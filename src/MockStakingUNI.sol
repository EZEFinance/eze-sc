// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockStakingUNI {
    IERC20 public immutable mockUNI;

    event EmergencyWithdraw(address indexed withdrawer, uint256 amount);
    event WithdrawAll(address indexed withdrawer, uint256 amount);
    event Staked(address indexed staker, uint256 amount, uint256 durationInDays);

    struct UserDetails {
        uint256 amountStaked;
        uint256 numberOfDays;
        uint256 registrationTimestamp;
        bool isValid;
    }

    mapping(address => UserDetails) public stakes;
    uint256 public totalAmountStaked;
    uint8 public fixedAPY;
    address public immutable owner;
    uint256 public durationInDays;
    uint256 public maxAmountStaked;
    uint256 public startStake;

    constructor(
        address _mockUNI,
        uint8 _fixedAPY,
        uint256 _durationInDays,
        uint256 _maxAmountStaked
    ) {
        require(_mockUNI != address(0), "Invalid token address");
        mockUNI = IERC20(_mockUNI);
        owner = msg.sender;
        fixedAPY = _fixedAPY;
        durationInDays = _durationInDays;
        maxAmountStaked = _maxAmountStaked;
        startStake = block.timestamp;
    }

    function getAmountStakeByUser(address _user) external view returns (uint256) {
        return stakes[_user].amountStaked;
    }

    function getMyStakedAmount() external view returns (uint256) {
        return stakes[msg.sender].amountStaked;
    }

    function stake(uint256 _days, uint256 _amount) external {
        require(msg.sender != address(0), "Zero address detected");
        require(_amount > 0, "Amount must be greater than 0");
        require(_amount <= maxAmountStaked, "Exceeds max stake amount");
        require(_checkDuration(), "Staking period has ended");
        require(totalAmountStaked + _amount <= maxAmountStaked, "Total stake limit reached");

        mockUNI.transferFrom(msg.sender, address(this), _amount);
        totalAmountStaked += _amount;

        if (stakes[msg.sender].isValid) {
            // Add to existing stake
            stakes[msg.sender].amountStaked += _amount;
            stakes[msg.sender].registrationTimestamp = block.timestamp;
        } else {
            stakes[msg.sender] = UserDetails(_amount, _days, block.timestamp, true);
        }

        emit Staked(msg.sender, _amount, _days);
    }

    function emergencyWithdraw(uint256 _amount) external {
        require(msg.sender != address(0), "Zero address detected");
        require(stakes[msg.sender].amountStaked >= _amount, "Insufficient funds");
        require(stakes[msg.sender].isValid, "User cannot withdraw");

        uint256 penalty = (_amount * 10) / 100; // 10% penalty
        uint256 finalAmount = _amount - penalty;

        stakes[msg.sender].amountStaked -= _amount;
        if (stakes[msg.sender].amountStaked == 0) {
            stakes[msg.sender].isValid = false;
        }
        totalAmountStaked -= _amount;
        
        mockUNI.transfer(msg.sender, finalAmount);
        
        emit EmergencyWithdraw(msg.sender, finalAmount);
    }

    function withdraw() external {
        require(msg.sender != address(0), "Zero address detected");
        require(stakes[msg.sender].isValid, "User cannot withdraw");
        require(block.timestamp >= stakes[msg.sender].registrationTimestamp + stakes[msg.sender].numberOfDays * 1 days, "Stake period not ended");

        uint256 reward = _calculateReward(msg.sender, stakes[msg.sender].numberOfDays);
        uint256 totalToPay = stakes[msg.sender].amountStaked + reward;

        totalAmountStaked -= stakes[msg.sender].amountStaked;
        stakes[msg.sender].amountStaked = 0;
        stakes[msg.sender].isValid = false;

        mockUNI.transfer(msg.sender, totalToPay);

        emit WithdrawAll(msg.sender, totalToPay);
    }

    function _calculateReward(address user, uint256 _days) private view returns (uint256) {
        return (stakes[user].amountStaked * fixedAPY * _days) / 36500;
    }

    function _checkDuration() private view returns (bool) {
        return (block.timestamp <= startStake + durationInDays * 1 days);
    }

    function withdrawToOwner() external {
        require(msg.sender == owner, "Not owner");
        uint256 oneYearAfter = startStake + durationInDays * 1 days + 365 days;
        require(block.timestamp > oneYearAfter, "Not yet time to withdraw");

        mockUNI.transfer(owner, mockUNI.balanceOf(address(this)));

        emit WithdrawAll(owner, mockUNI.balanceOf(address(this)));
    }

    receive() external payable {}
}
