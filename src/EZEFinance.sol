// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { UniversalRouter } from "@uniswap/universal-router/contracts/UniversalRouter.sol";
import { Commands } from "@uniswap/universal-router/contracts/libraries/Commands.sol";
import { IPoolManager } from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import { IV4Router } from "@uniswap/v4-periphery/src/interfaces/IV4Router.sol";
import { Actions } from "@uniswap/v4-periphery/src/libraries/Actions.sol";
import { IPermit2 } from "@uniswap/permit2/src/interfaces/IPermit2.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract EZEFinance {
    using SafeERC20 for IERC20;

    UniversalRouter public immutable router;
    mapping(address => mapping(address => uint256)) private balances;

    event Deposited(address indexed token, address indexed from, address indexed to, uint256 amount);
    event Withdrawn(address indexed token, address indexed from, address indexed to, uint256 amount);
    event Swapped(
        address indexed tokenIn,
        address indexed tokenOut,
        address indexed user,
        uint256 amountIn,
        uint256 amountOut
    );

    constructor(address _router) {
        router = UniversalRouter(_router);
    }

    function deposit(
        address token,
        address from,
        address to,
        uint256 amount
    ) external {
        require(token != address(0), "Invalid token address");
        require(from != address(0), "Invalid from address");
        require(to != address(0), "Invalid to address");
        require(amount > 0, "Amount must be greater than 0");

        IERC20(token).safeTransferFrom(from, address(this), amount);
        balances[token][to] += amount;
        
        emit Deposited(token, from, to, amount);
    }

    function withdraw(
        address token,
        address from,
        address to,
        uint256 amount
    ) external {
        require(token != address(0), "Invalid token address");
        require(from != address(0), "Invalid from address");
        require(to != address(0), "Invalid to address");
        require(amount > 0, "Amount must be greater than 0");
        require(balances[token][from] >= amount, "Insufficient balance");
        require(msg.sender == from || msg.sender == to, "Unauthorized");

        balances[token][from] -= amount;
        IERC20(token).safeTransfer(to, amount);
        
        emit Withdrawn(token, from, to, amount);
    }

    function getBalance(address token, address account) external view returns (uint256) {
        return balances[token][account];
    }

    function swapExactInputSingle(
        address tokenIn,
        address tokenOut,
        PoolKey calldata key,
        uint128 amountIn,
        uint128 minAmountOut
    ) external returns (uint256 amountOut) {
        require(tokenIn != address(0), "Invalid input token");
        require(tokenOut != address(0), "Invalid output token");
        require(tokenIn == address(key.currency0), "Token in mismatch with pool");
        require(tokenOut == address(key.currency1), "Token out mismatch with pool");
        require(balances[tokenIn][msg.sender] >= amountIn, "Insufficient balance");
        
        balances[tokenIn][msg.sender] -= amountIn;

        bytes memory commands = abi.encodePacked(uint8(Commands.V4_SWAP));
        bytes[] memory inputs = new bytes[](1);

        bytes memory actions = abi.encodePacked(
            uint8(Actions.SWAP_EXACT_IN_SINGLE),
            uint8(Actions.SETTLE_ALL),
            uint8(Actions.TAKE_ALL)
        );

        bytes[] memory params = new bytes[](3);
        params[0] = abi.encode(
            IV4Router.ExactInputSingleParams({
                poolKey: key,
                zeroForOne: true,
                amountIn: amountIn,
                amountOutMinimum: minAmountOut,
                sqrtPriceLimitX96: uint160(0),
                hookData: bytes("")
            })
        );
        params[1] = abi.encode(tokenIn, amountIn);
        params[2] = abi.encode(tokenOut, minAmountOut);

        inputs[0] = abi.encode(actions, params);

        router.execute(commands, inputs, block.timestamp);

        amountOut = IERC20(tokenOut).balanceOf(address(this));
        require(amountOut >= minAmountOut, "Insufficient output amount");

        balances[tokenOut][msg.sender] += amountOut;
        
        emit Swapped(tokenIn, tokenOut, msg.sender, amountIn, amountOut);
        
        return amountOut;
    }
}