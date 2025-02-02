// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract EZEFinance is Ownable, ReentrancyGuard, Pausable {
    address public immutable swapRouter;
    
    event Deposit(address indexed token, address indexed from, address indexed to, uint256 amount);
    event Withdrawal(address indexed token, address indexed from, address indexed to, uint256 amount);
    event Swap(address indexed tokenIn, address indexed tokenOut, address indexed user, uint256 amountIn, uint256 amountOut);

    constructor(address _swapRouter) Ownable(msg.sender) {
        require(_swapRouter != address(0), "Invalid router address");
        swapRouter = _swapRouter;
    }

    function deposit(address token, address from, address to, uint256 amount) 
        external 
        whenNotPaused 
        nonReentrant 
    {
        require(amount > 0, "Invalid amount");
        require(token != address(0), "Invalid token address");
        require(from != address(0) && to != address(0), "Invalid address");
        
        bool success = IERC20(token).transferFrom(from, to, amount);
        require(success, "Transfer failed");
        
        emit Deposit(token, from, to, amount);
    }

    function withdraw(address token, address from, address to, uint256 amount) 
        external 
        whenNotPaused 
        nonReentrant 
    {
        require(amount > 0, "Invalid amount");
        require(token != address(0), "Invalid token address");
        require(from != address(0) && to != address(0), "Invalid address");
        require(from == msg.sender, "Unauthorized withdrawal");
        
        bool success = IERC20(token).transferFrom(from, to, amount);
        require(success, "Transfer failed");
        
        emit Withdrawal(token, from, to, amount);
    }

    function swap(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) external whenNotPaused nonReentrant returns (uint256 amountOut) {
        require(amountIn > 0, "Invalid amount");
        require(tokenIn != address(0) && tokenOut != address(0), "Invalid token address");
        require(tokenIn != tokenOut, "Same tokens");

        bool success = IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        require(success, "Transfer failed");
        
        success = IERC20(tokenIn).approve(swapRouter, amountIn);
        require(success, "Approval failed");

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: fee,
            recipient: msg.sender,  
            deadline: block.timestamp + 15,
            amountIn: amountIn,
            amountOutMinimum: amountOutMinimum,
            sqrtPriceLimitX96: 0  
        });

        try ISwapRouter(swapRouter).exactInputSingle(params) returns (uint256 _amountOut) {
            amountOut = _amountOut;
        } catch {
            IERC20(tokenIn).approve(swapRouter, 0);
            revert("Swap failed");
        }
        
        success = IERC20(tokenIn).approve(swapRouter, 0);
        require(success, "Failed to reset approval");
        
        emit Swap(tokenIn, tokenOut, msg.sender, amountIn, amountOut);
        return amountOut;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}