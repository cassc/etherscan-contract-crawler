// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract Staking is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    event Staked(address indexed user, uint256 indexed months, uint256 amount);
    event Withdrawn(address indexed user, uint256 indexed months, uint256 amount, uint256 penalty);
    event Claimed(address indexed user, uint256 indexed months, uint256 amount);

    IERC20 public plsfi;

    struct StakeTime {
        uint256 apy;                    // 4 decimals. 2000 = 20%
        uint256 withdrawPenalty;        // 4 decimals. 500 = 5%
        uint256 lockDuration;
    }

    struct UserStake {
        uint256 amount;
        uint256 lastClaimed;
        uint256 lockTime;
        uint256 pendingRewards;
        uint256 rewardsClaimed;
    }

    // month -> StakeTime
    mapping(uint256 => StakeTime) public stakeTimeframes;

    // month -> wallet -> UserStake
    mapping(uint256 => mapping(address => UserStake)) public userStakes;

    uint256 public lockedAmount;
    uint256 public claimCooldown = 24 hours;
    uint256 public endTime = 1725213600;

    bool public takeWithdrawPenalty = true;


    constructor(address _plsfi) {
        require(_plsfi != address(0), "Cannot be zero address");
        plsfi = IERC20(_plsfi);

        stakeTimeframes[1] = StakeTime({
            apy: 2000,
            withdrawPenalty: 500,
            lockDuration: 30 days
        });
        stakeTimeframes[3] = StakeTime({
            apy: 3500,
            withdrawPenalty: 800,
            lockDuration: 90 days
        });
        stakeTimeframes[6] = StakeTime({
            apy: 4500,
            withdrawPenalty: 1000,
            lockDuration: 180 days
        });
        stakeTimeframes[12] = StakeTime({
            apy: 7000,
            withdrawPenalty: 1400,
            lockDuration: 365 days
        });
    }

    function adminWithdraw(uint256 amount) external onlyOwner {
        require(amount > 0, "0 amount");
        uint256 currentBalance = plsfi.balanceOf(address(this));
        require(currentBalance >= lockedAmount + amount, "Cannot withdraw from staked");
        plsfi.safeTransfer(msg.sender, amount);
    }

    function setEndTime(uint256 _endTime) external onlyOwner {
        require(_endTime > block.timestamp, "Cannot be past");
        endTime = _endTime;
    }

    function setClaimCooldown(uint256 _claimCooldown) external onlyOwner {
        claimCooldown = _claimCooldown;
    }

    function setWithdrawPenalty(bool _takeWithdrawPenalty) external onlyOwner {
        takeWithdrawPenalty = _takeWithdrawPenalty;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function stake(uint256 months, uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Staking 0 amount");
        StakeTime memory timeframe = stakeTimeframes[months];
        require(timeframe.apy > 0, "Incorrect months");
        
        uint256 rewardsDue = getRewards(msg.sender, months);
        plsfi.safeTransferFrom(msg.sender, address(this), amount);
        lockedAmount += amount;

        UserStake storage userStake = userStakes[months][msg.sender];
        userStake.amount += amount;
        userStake.lastClaimed = block.timestamp;
        userStake.pendingRewards = rewardsDue;
        userStake.lockTime = block.timestamp + timeframe.lockDuration;
        emit Staked(msg.sender, months, amount);
    }

    function withdraw(uint256 months, uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Staking 0 amount");
        StakeTime memory timeframe = stakeTimeframes[months];
        require(timeframe.apy > 0, "Incorrect months");

        uint256 rewardsDue = getRewards(msg.sender, months);
        UserStake storage userStake = userStakes[months][msg.sender];
        require(userStake.amount >= amount, "Not enough staked");
        uint256 penalty;
        if (takeWithdrawPenalty && block.timestamp < userStake.lockTime) {
            penalty = amount * timeframe.withdrawPenalty / 1e4;
        }
        uint256 withdrawAmount = amount - penalty;
        plsfi.safeTransfer(msg.sender, withdrawAmount);
        lockedAmount -= amount;

        userStake.amount -= amount;
        userStake.lastClaimed = block.timestamp;
        userStake.pendingRewards = rewardsDue;
        emit Withdrawn(msg.sender, months, amount, penalty);
    }

    function claim(uint256 months) external nonReentrant whenNotPaused {
        UserStake storage userStake = userStakes[months][msg.sender];
        require(block.timestamp >= userStake.lastClaimed + claimCooldown, "Already claimed for the day");
        uint256 rewardsDue = getRewards(msg.sender, months);
        uint256 currentBalance = plsfi.balanceOf(address(this));
        require(currentBalance >= lockedAmount + rewardsDue, "Come later for rewards");
        
        userStake.lastClaimed = block.timestamp;
        userStake.pendingRewards = 0;
        plsfi.safeTransfer(msg.sender, rewardsDue);
        userStake.rewardsClaimed += rewardsDue;
        emit Claimed(msg.sender, months, rewardsDue);
    }

    function getTokenRewardPerSec(uint256 amount, uint256 months) internal view returns (uint256) {
        uint256 apy = stakeTimeframes[months].apy;
        return (amount * apy) / (1e4 * 365 days);
    }

    function getRewards(address user, uint256 months) public view returns (uint256 rewards) {
        UserStake memory userStake = userStakes[months][user];
        uint256 toTime = block.timestamp > endTime ? endTime : block.timestamp;
        if (userStake.lastClaimed < toTime) {
            uint256 rewardPerSec = getTokenRewardPerSec(userStake.amount, months);
            rewards = rewardPerSec * (toTime - userStake.lastClaimed);
        }
        rewards += userStake.pendingRewards;
    }

    function getUserStakeInfo(address user) external view returns (UserStake[] memory stakeInfo) {
        stakeInfo = new UserStake[](4);
        stakeInfo[0] = userStakes[1][user];
        stakeInfo[1] = userStakes[3][user];
        stakeInfo[2] = userStakes[6][user];
        stakeInfo[3] = userStakes[12][user];
    }
}