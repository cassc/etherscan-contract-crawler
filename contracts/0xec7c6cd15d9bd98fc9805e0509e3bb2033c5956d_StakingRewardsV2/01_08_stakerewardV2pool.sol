// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IesLBR.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IesLBRBoost {
    function getUserBoost(
        address user,
        uint256 userUpdatedAt,
        uint256 finishAt
    ) external view returns (uint256);
}

contract StakingRewardsV2 is Ownable {
    using SafeERC20 for IERC20;
    // Immutable variables for staking and rewards tokens
    IERC20 public immutable stakingToken;
    IesLBR public immutable rewardsToken;
    IesLBRBoost public esLBRBoost;

    // Duration of rewards to be paid out (in seconds)
    uint256 public duration = 604_800;
    // Timestamp of when the rewards finish
    uint256 public finishAt;
    // Minimum of last updated time and reward finish time
    uint256 public updatedAt;
    // Reward to be paid out per second
    uint256 public rewardRatio;
    // Sum of (reward ratio * dt * 1e18 / total supply)
    uint256 public rewardPerTokenStored;
    // User address => rewardPerTokenStored
    mapping(address => uint256) public userRewardPerTokenPaid;
    // User address => rewards to be claimed
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public userUpdatedAt;

    // Total staked
    uint256 public totalSupply;
    // User address => staked amount
    mapping(address => uint256) public balanceOf;

    ///events
    event StakeToken(address indexed user, uint256 amount, uint256 time);
    event WithdrawToken(address indexed user, uint256 amount, uint256 time);
    event ClaimReward(address indexed user, uint256 amount, uint256 time);
    event NotifyRewardChanged(uint256 addAmount, uint256 time);
    event DurationChanged(uint256 duration, uint256 time);
    event BoostChanged(address boostAddr, uint256 time);

    constructor(address _stakingToken, address _rewardToken, address _boost) {
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IesLBR(_rewardToken);
        esLBRBoost = IesLBRBoost(_boost);
    }

    // Update user's claimable reward data and record the timestamp.
    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();

        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
            userUpdatedAt[_account] = block.timestamp;
        }
        _;
    }

    // Returns the last time the reward was applicable
    function lastTimeRewardApplicable() public view returns (uint256) {
        return _min(finishAt, block.timestamp);
    }

    // Calculates and returns the reward per token
    function rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }

        return rewardPerTokenStored + (rewardRatio * (lastTimeRewardApplicable() - updatedAt) * 1e18) / totalSupply;
    }

    // Allows users to stake a specified amount of tokens
    function stake(uint256 _amount) external updateReward(msg.sender) {
        require(_amount != 0, "amount = 0");
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        balanceOf[msg.sender] += _amount;
        totalSupply += _amount;
        emit StakeToken(msg.sender, _amount, block.timestamp);
    }

    // Allows users to withdraw a specified amount of staked tokens
    function withdraw(uint256 _amount) external updateReward(msg.sender) {
        require(_amount != 0, "amount = 0");
        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        stakingToken.safeTransfer(msg.sender, _amount);
        emit WithdrawToken(msg.sender, _amount, block.timestamp);
    }

    function getBoost(address _account) public view returns (uint256) {
        return 100 * 1e18 + esLBRBoost.getUserBoost(_account, userUpdatedAt[_account], finishAt);
    }

    // Calculates and returns the earned rewards for a user
    function earned(address _account) public view returns (uint256) {
        return ((balanceOf[_account] * getBoost(_account) * (rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e38) + rewards[_account];
    }

    // Allows users to claim their earned rewards
    function getReward() external updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.mint(msg.sender, reward);
            emit ClaimReward(msg.sender, reward, block.timestamp);
        }
    }

    // Allows the owner to set the rewards duration
    function setRewardsDuration(uint256 _duration) external onlyOwner {
        require(finishAt < block.timestamp, "reward duration not finished");
        duration = _duration;
        emit DurationChanged(_duration, block.timestamp);
    }

    // Allows the owner to set the boost contract address
    function setBoost(address _boost) external onlyOwner {
        esLBRBoost = IesLBRBoost(_boost);
        emit BoostChanged(_boost, block.timestamp);
    }

    // Allows the owner to set the mining rewards.
    function notifyRewardAmount(uint256 _amount) external onlyOwner updateReward(address(0)) {
        if (block.timestamp >= finishAt) {
            rewardRatio = _amount / duration;
        } else {
            uint256 remainingRewards = (finishAt - block.timestamp) * rewardRatio;
            rewardRatio = (_amount + remainingRewards) / duration;
        }

        require(rewardRatio != 0, "reward ratio = 0");

        finishAt = block.timestamp + duration;
        updatedAt = block.timestamp;
        emit NotifyRewardChanged(_amount, block.timestamp);
    }

    function _min(uint256 x, uint256 y) private pure returns (uint256) {
        return x <= y ? x : y;
    }
}