// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/forge-std/src/Test.sol";
import "../src/MockStakingUSDC.sol"; 
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./MockUSDC.t.sol";

contract MockStakingUSDCTest is Test {
    MockStakingUSDC public stakingContract;
    MockUSDC public USDC;

    address public user1;
    address public user2;
    address public owner;

    uint8 public fixedAPY = 10;
    uint256 public durationInDays = 30;
    uint256 public maxAmountStaked = 1000 * 10**18;

    function setUp() public {
        USDC = new MockUSDC();
        
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        USDC.mint(user1, 1000 * 10**18);
        USDC.mint(user2, 1000 * 10**18);
        USDC.mint(address(this), 1000 * 10**18); // Mint tokens to owner for rewards
        
        stakingContract = new MockStakingUSDC(address(USDC), fixedAPY, durationInDays, maxAmountStaked);
        
        // Transfer some tokens to the staking contract for rewards
        USDC.approve(address(stakingContract), 1000 * 10**18);
        USDC.transfer(address(stakingContract), 100 * 10**18);
    }

    function testStake() public {
        uint256 stakeAmount = 500 * 10**18;
        vm.startPrank(user1);
        USDC.approve(address(stakingContract), stakeAmount);
        
        stakingContract.stake(durationInDays, stakeAmount);
        
        uint256 stakedAmount = stakingContract.getMyStakedAmount();
        assertEq(stakedAmount, stakeAmount, "Stake amount mismatch");

        vm.stopPrank();
    }

    function testWithdraw() public {
        uint256 stakeAmount = 500 * 10**18;
        vm.startPrank(user1);
        USDC.approve(address(stakingContract), stakeAmount);
        stakingContract.stake(durationInDays, stakeAmount);

        // Advance time exactly to the end of staking period
        vm.warp(block.timestamp + durationInDays * 1 days);

        uint256 initialBalance = USDC.balanceOf(user1);
        stakingContract.withdraw();
        uint256 finalBalance = USDC.balanceOf(user1);
        
        // Calculate expected reward for exactly 30 days
        // APY needs to be prorated for the 30-day period
        uint256 expectedReward = (stakeAmount * fixedAPY * durationInDays) / (365 * 100);
        uint256 expectedFinalBalance = initialBalance + stakeAmount + expectedReward;
        
        assertEq(finalBalance, expectedFinalBalance, "Withdrawal amount incorrect");
        assertTrue(finalBalance > initialBalance, "No reward received");
        assertTrue(
            finalBalance <= initialBalance + stakeAmount + expectedReward, 
            "Reward exceeds maximum APY"
        );
        
        vm.stopPrank();
    }

    function testEmergencyWithdraw() public {
        uint256 stakeAmount = 500 * 10**18;
        uint256 withdrawAmount = 250 * 10**18;
        
        vm.startPrank(user1);
        USDC.approve(address(stakingContract), stakeAmount);
        stakingContract.stake(durationInDays, stakeAmount);

        uint256 initialBalance = USDC.balanceOf(user1);
        stakingContract.emergencyWithdraw(withdrawAmount);
        uint256 finalBalance = USDC.balanceOf(user1);

        // Calculate expected balance after penalty
        uint256 expectedPenalty = withdrawAmount * 10 / 100; // 10% penalty
        uint256 expectedBalance = initialBalance + withdrawAmount - expectedPenalty;
        
        assertEq(finalBalance, expectedBalance, "Emergency withdraw amount incorrect");
        assertTrue(finalBalance < initialBalance + withdrawAmount, "No penalty applied");
        
        vm.stopPrank();
    }

    function testOwnerWithdraw() public {
        uint256 stakeAmount = 500 * 10**18;
        vm.prank(user1);
        USDC.approve(address(stakingContract), stakeAmount);
        
        vm.prank(user1);
        stakingContract.stake(durationInDays, stakeAmount);

        // Advance time to after staking period plus grace period
        // Assuming a 7-day grace period for users to withdraw
        vm.warp(block.timestamp + (durationInDays * 1 days) + 7 days);

        uint256 initialContractBalance = USDC.balanceOf(address(stakingContract));
        uint256 initialOwnerBalance = USDC.balanceOf(owner);

        vm.prank(owner);
        stakingContract.withdrawToOwner();

        uint256 finalContractBalance = USDC.balanceOf(address(stakingContract));
        uint256 finalOwnerBalance = USDC.balanceOf(owner);
        
        assertEq(finalContractBalance, 0, "Contract should have zero balance");
        assertEq(
            finalOwnerBalance, 
            initialOwnerBalance + initialContractBalance, 
            "Owner balance incorrect"
        );
    }
}