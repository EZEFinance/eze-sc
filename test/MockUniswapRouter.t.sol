// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockUniswapRouter {
    uint256 private expectedOutput;
    
    // Emulate the exact input single function from Uniswap V3 Router
    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut) {
        // Transfer tokens from sender to this contract (simulating swap)
        IERC20(params.tokenIn).transferFrom(msg.sender, address(this), params.amountIn);
        
        // Transfer the expected output amount of tokens to the recipient
        IERC20(params.tokenOut).transfer(params.recipient, expectedOutput);
        
        return expectedOutput;
    }
    
    // Struct to match Uniswap V3's ExactInputSingleParams
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }
    
    // Function to set the expected output amount for testing
    function setExpectedOutput(uint256 _expectedOutput) external {
        expectedOutput = _expectedOutput;
    }
    
    // Function to get the expected output amount (for verification)
    function getExpectedOutput() external view returns (uint256) {
        return expectedOutput;
    }
    
    // Helper function to handle token approvals for testing
    function approveToken(address token, address spender, uint256 amount) external {
        IERC20(token).approve(spender, amount);
    }
}