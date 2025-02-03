// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/forge-std/src/Test.sol";
import "../src/EZEFinance.sol";
import "./MockUSDC.t.sol";
import "./MockUNI.t.sol";  
import "./MockUniswapRouter.t.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error OwnableUnauthorizedAccount(address account);
error EnforcedPause();

contract EZEFinanceTest is Test {
    EZEFinance public ezeFinance;
    MockUniswapRouter public mockRouter;
    MockUSDC public USDC;
    MockUNI public UNI;
    
    address public owner;
    address public user1;
    address public user2;
    
    uint24 constant MOCK_FEE = 3000; // 0.3%
    uint256 constant INITIAL_USDC_SUPPLY = 1_000_000 * 1e6; // 1M USDC with 6 decimals
    uint256 constant INITIAL_UNI_SUPPLY = 1_000_000 * 1e18; // 1M UNI with 18 decimals
    uint256 constant TEST_USDC_AMOUNT = 100 * 1e6; // 100 USDC
    uint256 constant TEST_UNI_AMOUNT = 100 * 1e18; // 100 UNI
    
    event Deposit(address indexed token, address indexed from, address indexed to, uint256 amount);
    event Withdrawal(address indexed token, address indexed from, address indexed to, uint256 amount);
    event Swap(address indexed tokenIn, address indexed tokenOut, address indexed user, uint256 amountIn, uint256 amountOut);
    
    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        USDC = new MockUSDC();
        UNI = new MockUNI();
        
        mockRouter = new MockUniswapRouter();
        
        ezeFinance = new EZEFinance(address(mockRouter));
        
        USDC.transfer(user1, TEST_USDC_AMOUNT);
        UNI.transfer(user2, TEST_UNI_AMOUNT);
        
        UNI.transfer(address(mockRouter), TEST_UNI_AMOUNT * 10); 
    }

    function test_RevertWhen_DepositWhenPaused() public {
        ezeFinance.pause();
        
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(EnforcedPause.selector));
        ezeFinance.deposit(address(USDC), user1, user2, TEST_USDC_AMOUNT);
        vm.stopPrank();
    }
    
    function test_RevertWhen_UnauthorizedPause() public {
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, user1));
        ezeFinance.pause();
        vm.stopPrank();
    }
    
    function test_Deployment() public view {
        assertEq(address(ezeFinance.swapRouter()), address(mockRouter));
        assertEq(ezeFinance.owner(), owner);
    }
    
    function test_Deposit() public {
        vm.startPrank(user1);
        USDC.approve(address(ezeFinance), TEST_USDC_AMOUNT);
        
        vm.expectEmit(true, true, true, true);
        emit Deposit(address(USDC), user1, user2, TEST_USDC_AMOUNT);
        
        ezeFinance.deposit(address(USDC), user1, user2, TEST_USDC_AMOUNT);
        assertEq(USDC.balanceOf(user2), TEST_USDC_AMOUNT);
        vm.stopPrank();
    }
    
    function test_RevertWhen_DepositZeroAmount() public {
        vm.startPrank(user1);
        vm.expectRevert("Invalid amount");
        ezeFinance.deposit(address(USDC), user1, user2, 0);
        vm.stopPrank();
    }
    
    function test_RevertWhen_DepositInvalidToken() public {
        vm.startPrank(user1);
        vm.expectRevert("Invalid token address");
        ezeFinance.deposit(address(0), user1, user2, TEST_USDC_AMOUNT);
        vm.stopPrank();
    }
    
    function test_PauseAndUnpause() public {
        ezeFinance.pause();
        assertTrue(ezeFinance.paused());
        
        ezeFinance.unpause();
        assertFalse(ezeFinance.paused());
    }
    
    function test_Withdraw() public {
        vm.startPrank(user1);
        USDC.approve(address(ezeFinance), TEST_USDC_AMOUNT);
        ezeFinance.deposit(address(USDC), user1, user2, TEST_USDC_AMOUNT);
        vm.stopPrank();
        
        vm.startPrank(user2);
        USDC.approve(address(ezeFinance), TEST_USDC_AMOUNT);
        
        vm.expectEmit(true, true, true, true);
        emit Withdrawal(address(USDC), user2, user1, TEST_USDC_AMOUNT);
        
        ezeFinance.withdraw(address(USDC), user2, user1, TEST_USDC_AMOUNT);
        assertEq(USDC.balanceOf(user1), TEST_USDC_AMOUNT);
        vm.stopPrank();
    }
    
    function test_Swap() public {
        uint256 expectedOutput = TEST_UNI_AMOUNT * 95 / 100;
        mockRouter.setExpectedOutput(expectedOutput);
        
        vm.startPrank(user1);
        USDC.approve(address(ezeFinance), TEST_USDC_AMOUNT);
        
        vm.expectEmit(true, true, true, true);
        emit Swap(address(USDC), address(UNI), user1, TEST_USDC_AMOUNT, expectedOutput);
        
        uint256 amountOut = ezeFinance.swap(
            address(USDC),
            address(UNI),
            MOCK_FEE,
            TEST_USDC_AMOUNT,
            expectedOutput
        );
        
        assertEq(amountOut, expectedOutput);
        assertEq(UNI.balanceOf(user1), expectedOutput);
        vm.stopPrank();
    }
    
    function test_RevertWhen_SwapSameToken() public {
        vm.startPrank(user1);
        vm.expectRevert("Same tokens");
        ezeFinance.swap(
            address(USDC),
            address(USDC),
            MOCK_FEE,
            TEST_USDC_AMOUNT,
            0
        );
        vm.stopPrank();
    }
}