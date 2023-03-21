//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

// Inheritance
import "../interfaces/IStakingRewards.sol";
import "../interfaces/Pausable.sol";
import "../interfaces/RewardsDistributionRecipient.sol";
import "../interfaces/MintableToken.sol";

// based on synthetix
contract StakingRewards is IStakingRewards, RewardsDistributionRecipient, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct Times {
        uint32 periodFinish;
        uint32 rewardsDuration;
        uint32 lastUpdateTime;
        uint96 totalRewardsSupply;
    }

    uint256 public immutable maxEverTotalRewards;

    IERC20 public immutable rewardsToken;
    IERC20 public immutable stakingToken;

    uint256 public rewardRate;
    uint256 public rewardPerTokenStored;
    
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    Times public timeData;
    bool public stopped;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event FarmingFinished();

    modifier whenActive() {
        require(!stopped, "farming is stopped");
        _;
    }

    modifier updateReward(address account) virtual {
        uint256 newRewardPerTokenStored = rewardPerToken();
        rewardPerTokenStored = newRewardPerTokenStored;
        timeData.lastUpdateTime = uint32(lastTimeRewardApplicable());

        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = newRewardPerTokenStored;
        }

        _;
    }

    constructor(
        address _owner,
        address _rewardsDistribution,
        address _stakingToken,
        address _rewardsToken
    ) Owned(_owner) {
        // works like sanity check for tokens
        IERC20(_stakingToken).totalSupply();
        IERC20(_rewardsToken).totalSupply();

        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);

        rewardsDistribution = _rewardsDistribution;

        timeData.rewardsDuration = 2592000; // 30 days
        maxEverTotalRewards = MintableToken(_rewardsToken).maxAllowedTotalSupply();
    }


    function notifyRewardAmount(
        uint256 _reward
    ) override virtual external whenActive onlyRewardsDistribution updateReward(address(0)) {
        Times memory t = timeData;
        uint256 newRewardRate;

        if (block.timestamp >= t.periodFinish) {
            newRewardRate = _reward / t.rewardsDuration;
        } else {
            uint256 remaining = t.periodFinish - block.timestamp;
            uint256 leftover = remaining.mul(rewardRate);
            newRewardRate = _reward.add(leftover) / t.rewardsDuration;
        }

        require(newRewardRate != 0, "invalid rewardRate");

        rewardRate = newRewardRate;

        // always increasing by _reward even if notification is in a middle of period
        // because leftover is included
        uint256 totalRewardsSupply = SafeMath.add(timeData.totalRewardsSupply, _reward);
        require(totalRewardsSupply <= maxEverTotalRewards, "rewards overflow");

        timeData.totalRewardsSupply = uint96(totalRewardsSupply);

        // if this is a fresh start, we will not be setting up periodFinish and lastUpdateTime
        // it will be set up when the user first stakes
        // that way we will avoid generating dust between start and first stake
        if (t.periodFinish != 0) {
            timeData.lastUpdateTime = uint32(block.timestamp);
            timeData.periodFinish = uint32(block.timestamp + t.rewardsDuration);
        }

        emit RewardAdded(_reward);
    }

    function setRewardsDuration(uint256 _rewardsDuration) external whenActive onlyOwner {
        require(_rewardsDuration != 0, "empty _rewardsDuration");

        require(
            block.timestamp > timeData.periodFinish,
            "Previous period must be complete before changing the duration"
        );

        timeData.rewardsDuration = uint32(_rewardsDuration);
        emit RewardsDurationUpdated(_rewardsDuration);
    }

    // when farming was started with 1y and 12tokens
    // and we want to finish after 4 months, we need to end up with situation
    // like we were starting with 4mo and 4 tokens.
    function finishFarming() virtual external whenActive onlyOwner {
        stopped = true;
        emit FarmingFinished();

        Times memory t = timeData;

        if (t.periodFinish == 0 && t.totalRewardsSupply != 0) {
            // it was notified but nobody staked yet
            timeData.lastUpdateTime = 0;
            timeData.totalRewardsSupply = 0;
            return;
        }

        require(block.timestamp < t.periodFinish, "can't stop if not started or already finished");

        if (_totalSupply != 0) {
            uint256 remaining = t.periodFinish - block.timestamp;
            timeData.rewardsDuration = uint32(t.rewardsDuration - remaining);
        }

        timeData.periodFinish = uint32(block.timestamp);
    }

    function exit() override external {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    function stake(uint256 amount) override external {
        _stake(msg.sender, amount, false);
    }

    function periodFinish() external view returns (uint256) {
        return timeData.periodFinish;
    }

    function rewardsDuration() external view returns (uint256) {
        return timeData.rewardsDuration;
    }

    function lastUpdateTime() external view returns (uint256) {
        return timeData.lastUpdateTime;
    }

    function balanceOf(address account) override external view returns (uint256) {
        return _balances[account];
    }

    function getRewardForDuration() override external view returns (uint256) {
        return rewardRate * timeData.rewardsDuration;
    }

    function totalSupply() override external view returns (uint256) {
        return _totalSupply;
    }

    function version() external pure virtual returns (uint256) {
        return 1;
    }

    function withdraw(uint256 amount) override public {
        _withdraw(amount, msg.sender, msg.sender);
    }

    function getReward() override public {
        _getReward(msg.sender, msg.sender);
    }

    function lastTimeRewardApplicable() override public view returns (uint256) {
        return Math.min(block.timestamp, timeData.periodFinish);
    }

    function rewardPerToken() override public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }

        return rewardPerTokenStored + (
            (lastTimeRewardApplicable() - timeData.lastUpdateTime) * rewardRate * 1e18 / _totalSupply
        );
    }

    function earned(address account) override virtual public view returns (uint256) {
        // rewardPerToken() is always at least `rewardPerTokenStored`
        // `userRewardPerTokenPaid[account]` is at most == rewardPerToken()
        // so when we doing below calculation: rewardPerToken() >= userRewardPerTokenPaid[account], we do not underflow
        return (_balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account]) / 1e18) + rewards[account];
    }

    function _stake(address user, uint256 amount, bool migration)
        internal
        nonReentrant
        notPaused
        updateReward(user) // on first stake it will not update anything, all calculations will be 0
    {
        require(timeData.totalRewardsSupply != 0, "Stake period not started yet");
        require(amount != 0, "Cannot stake 0");

        // if we pass `rewardsDuration` check but `periodFinish` is empty, then staking is active and this is first user
        if (timeData.periodFinish == 0) {
            // set `periodFinish` on initial staking to avoid dust
            timeData.periodFinish = uint32(block.timestamp + timeData.rewardsDuration);
            timeData.lastUpdateTime = uint32(block.timestamp);
        }

        // `amount` is what we will transferFrom contract, so we can not overflow `totalSupply.totalBalance`
        _totalSupply = _totalSupply + amount;
        _balances[user] = _balances[user] + amount;

        if (migration) {
            // other contract will send tokens to us, this will save ~13K gas
        } else {
            // not using safe transfer, because we working with trusted tokens
            require(stakingToken.transferFrom(user, address(this), amount), "token transfer failed");
        }

        emit Staked(user, amount);
    }

    /// @param amount tokens to withdraw
    /// @param user address
    /// @param recipient address, where to send tokens, if we migrating token address can be zero
    function _withdraw(uint256 amount, address user, address recipient) internal nonReentrant updateReward(user) {
        require(amount != 0, "Cannot withdraw 0");

        uint256 userBalance = _balances[user];
        require(userBalance >= amount, "withdraw amount to high");

        // not using safe math, because there is no way to overflow if stake tokens not overflow
        _totalSupply = _totalSupply - amount;
        // not using safe math because of check "withdraw amount to high"
        _balances[user] = userBalance - amount;

        // not using safe transfer, because we working with trusted tokens
        require(stakingToken.transfer(recipient, amount), "token transfer failed");

        emit Withdrawn(user, amount);
    }

    /// @param user address
    /// @param recipient address, where to send reward
    function _getReward(address user, address recipient)
        internal
        virtual
        nonReentrant
        updateReward(user)
        returns (uint256 reward)
    {
        reward = rewards[user];

        if (reward != 0) {
            rewards[user] = 0;
            // not using safe transfer because reward is trusted token eg UMB
            require(rewardsToken.transfer(recipient, reward), "RewardTransferFailed");
            
            emit RewardPaid(user, reward);
        }
    }
}