// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract LPStaking is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Claimed(address indexed user, uint256 amount);

    IERC20 public lpToken;
    IERC20 public plsfi;

    struct UserStake {
        uint256 amount;
        uint256 lastClaimed;
        uint256 pendingRewards;
        uint256 rewardsClaimed;
    }

    // wallet -> UserStake
    mapping(address => UserStake) public userStakes;

    uint256 public claimCooldown = 24 hours;
    uint256 public endTime = 1725213600;
    uint256 public rewardRatePerToken = 38000000000000;     // 18 decimals

    constructor(address _lpToken, address _plsfi) {
        require(_lpToken != address(0), "Cannot be zero address");
        require(_plsfi != address(0), "Cannot be zero address");
        lpToken = IERC20(_lpToken);
        plsfi = IERC20(_plsfi);
    }

    function adminWithdraw(uint256 amount) external onlyOwner {
        require(amount > 0, "0 amount");
        plsfi.safeTransfer(msg.sender, amount);
    }

    function setEndTime(uint256 _endTime) external onlyOwner {
        require(_endTime > block.timestamp, "Cannot be past");
        endTime = _endTime;
    }

    function setClaimCooldown(uint256 _claimCooldown) external onlyOwner {
        claimCooldown = _claimCooldown;
    }

    function setRewardRatePerToken(uint256 _rewardRatePerToken) external onlyOwner {
        rewardRatePerToken = _rewardRatePerToken;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function stake(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Staking 0 amount");
        
        uint256 rewardsDue = getRewards(msg.sender);
        lpToken.safeTransferFrom(msg.sender, address(this), amount);

        UserStake storage userStake = userStakes[msg.sender];
        userStake.amount += amount;
        userStake.lastClaimed = block.timestamp;
        userStake.pendingRewards = rewardsDue;
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Staking 0 amount");

        uint256 rewardsDue = getRewards(msg.sender);
        UserStake storage userStake = userStakes[msg.sender];
        require(userStake.amount >= amount, "Not enough staked");
        lpToken.safeTransfer(msg.sender, amount);

        userStake.amount -= amount;
        userStake.lastClaimed = block.timestamp;
        userStake.pendingRewards = rewardsDue;
        emit Withdrawn(msg.sender, amount);
    }

    function claim() external nonReentrant whenNotPaused {
        UserStake storage userStake = userStakes[msg.sender];
        require(block.timestamp >= userStake.lastClaimed + claimCooldown, "Already claimed for the day");
        uint256 rewardsDue = getRewards(msg.sender);
        uint256 currentBalance = plsfi.balanceOf(address(this));
        require(currentBalance >= rewardsDue, "Come later for rewards");

        userStake.lastClaimed = block.timestamp;
        userStake.pendingRewards = 0;
        plsfi.safeTransfer(msg.sender, rewardsDue);
        userStake.rewardsClaimed += rewardsDue;
        emit Claimed(msg.sender, rewardsDue);
    }

    function getRewards(address user) public view returns (uint256 rewards) {
        UserStake memory userStake = userStakes[user];
        uint256 toTime = block.timestamp > endTime ? endTime : block.timestamp;
        if (userStake.lastClaimed < toTime) {
            rewards = userStake.amount * rewardRatePerToken * (toTime - userStake.lastClaimed) / 1e18;
        }
        rewards += userStake.pendingRewards;
    }

    function getAnnualReward(address user) external view returns (uint256 amount) {
        UserStake memory userStake = userStakes[user];
        return userStake.amount * rewardRatePerToken * (365 days) / 1e18;
    }
}