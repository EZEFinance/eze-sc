// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/EZEFinance.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/universal-router/contracts/UniversalRouter.sol";
import "@uniswap/v4-core/src/interfaces/IPoolManager.sol";

contract EZEFinanceTest is Test {
    EZEFinance public ezeFinance;
    UniversalRouter public router;
    address public constant MOCK_TOKEN_A = address(0x1);
    address public constant MOCK_TOKEN_B = address(0x2);
    address public constant USER_A = address(0x3);
    address public constant USER_B = address(0x4);

    event Deposited(address indexed token, address indexed from, address indexed to, uint256 amount);
    event Withdrawn(address indexed token, address indexed from, address indexed to, uint256 amount);
    event Swapped(
        address indexed tokenIn,
        address indexed tokenOut,
        address indexed user,
        uint256 amountIn,
        uint256 amountOut
    );

    function setUp() public {
        // Deploy mock router
        router = new UniversalRouter(
            address(0), // permit2
            address(0), // weth9
            address(0)  // seaport
        );
        
        // Deploy EZEFinance
        ezeFinance = new EZEFinance(address(router));

        // Setup mock tokens
        vm.mockCall(
            MOCK_TOKEN_A,
            abi.encodeWithSelector(IERC20.transferFrom.selector),
            abi.encode(true)
        );
        vm.mockCall(
            MOCK_TOKEN_A,
            abi.encodeWithSelector(IERC20.transfer.selector),
            abi.encode(true)
        );
        vm.mockCall(
            MOCK_TOKEN_B,
            abi.encodeWithSelector(IERC20.transferFrom.selector),
            abi.encode(true)
        );
        vm.mockCall(
            MOCK_TOKEN_B,
            abi.encodeWithSelector(IERC20.transfer.selector),
            abi.encode(true)
        );
    }

    function testDeposit() public {
        uint256 amount = 1000;
        
        vm.expectEmit(true, true, true, true);
        emit Deposited(MOCK_TOKEN_A, USER_A, USER_A, amount);
        
        vm.prank(USER_A);
        ezeFinance.deposit(MOCK_TOKEN_A, USER_A, USER_A, amount);
        
        assertEq(ezeFinance.getBalance(MOCK_TOKEN_A, USER_A), amount);
    }

    function testWithdraw() public {
        uint256 amount = 1000;
        
        // First deposit
        vm.prank(USER_A);
        ezeFinance.deposit(MOCK_TOKEN_A, USER_A, USER_A, amount);
        
        vm.expectEmit(true, true, true, true);
        emit Withdrawn(MOCK_TOKEN_A, USER_A, USER_B, amount);
        
        vm.prank(USER_A);
        ezeFinance.withdraw(MOCK_TOKEN_A, USER_A, USER_B, amount);
        
        assertEq(ezeFinance.getBalance(MOCK_TOKEN_A, USER_A), 0);
    }

    function testFailWithdrawInsufficientBalance() public {
        uint256 amount = 1000;
        
        vm.prank(USER_A);
        vm.expectRevert("Insufficient balance");
        ezeFinance.withdraw(MOCK_TOKEN_A, USER_A, USER_B, amount);
    }

    function testFailWithdrawUnauthorized() public {
        uint256 amount = 1000;
        
        // First deposit
        vm.prank(USER_A);
        ezeFinance.deposit(MOCK_TOKEN_A, USER_A, USER_A, amount);
        
        // Try to withdraw as unauthorized user
        vm.prank(USER_B);
        vm.expectRevert("Unauthorized");
        ezeFinance.withdraw(MOCK_TOKEN_A, USER_A, USER_B, amount);
    }

    function testSwapExactInputSingle() public {
        uint256 depositAmount = 1000;
        uint128 swapAmount = 500;
        uint128 minAmountOut = 450;
        
        // Setup mock pool key
        IPoolManager.PoolKey memory key = IPoolManager.PoolKey({
            currency0: Currency.wrap(MOCK_TOKEN_A),
            currency1: Currency.wrap(MOCK_TOKEN_B),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(address(0))
        });

        // First deposit
        vm.prank(USER_A);
        ezeFinance.deposit(MOCK_TOKEN_A, USER_A, USER_A, depositAmount);
        
        // Mock router execution
        vm.mockCall(
            address(router),
            abi.encodeWithSelector(UniversalRouter.execute.selector),
            abi.encode()
        );
        
        // Mock output token balance
        vm.mockCall(
            MOCK_TOKEN_B,
            abi.encodeWithSelector(IERC20.balanceOf.selector),
            abi.encode(minAmountOut)
        );

        vm.expectEmit(true, true, true, true);
        emit Swapped(MOCK_TOKEN_A, MOCK_TOKEN_B, USER_A, swapAmount, minAmountOut);
        
        vm.prank(USER_A);
        uint256 amountOut = ezeFinance.swapExactInputSingle(
            MOCK_TOKEN_A,
            MOCK_TOKEN_B,
            key,
            swapAmount,
            minAmountOut
        );
        
        assertEq(amountOut, minAmountOut);
        assertEq(ezeFinance.getBalance(MOCK_TOKEN_A, USER_A), depositAmount - swapAmount);
        assertEq(ezeFinance.getBalance(MOCK_TOKEN_B, USER_A), minAmountOut);
    }
}