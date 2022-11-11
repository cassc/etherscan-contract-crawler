// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "../openzeppelin-solidity-3.4.0/contracts/math/Math.sol";
import "../openzeppelin-solidity-3.4.0/contracts/math/SafeMath.sol";
import "../openzeppelin-solidity-3.4.0/contracts/token/ERC20/SafeERC20.sol";
import "../openzeppelin-solidity-3.4.0/contracts/utils/ReentrancyGuard.sol";

// Inheritance
import "./interfaces/IStakingRewards.sol";
import "./RewardsDistributionRecipient.sol";

contract StakingRewards is IStakingRewards, RewardsDistributionRecipient, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    /// The token staking rewards will be paid in.
    IERC20 public rewardsToken;
    /// The token which must be staked to earn rewards.
    IERC20 public stakingToken;
    /// The time at which reward distribution will be complete.
    uint256 public periodFinish = 0;
    /// The rate at which rewards will be distributed.
    uint256 public rewardRate = 0;
    /// How long rewards will be distributed after the staking period begins.
    uint256 public rewardsDuration = 135 days;
    /// The last time rewardPerTokenStored was updated.
    uint256 public lastUpdateTime;
    /// The lastest snapshot of the amount of reward allocated to each staked token.
    uint256 public rewardPerTokenStored;

    /// How much reward-per-token has been paid out to each user who has withdrawn their stake.
    mapping(address => uint256) public userRewardPerTokenPaid;
    /// How much reward each user has earned.
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    /* ========== CONSTRUCTOR ========== */

    /// Deploy a new StakingRewards contract with the specified parameters. (This should only be done by the StakingRewardsFactory.)
    constructor(
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken
    ) {
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
        rewardsDistribution = _rewardsDistribution;
    }

    /* ========== VIEWS ========== */

    /// Returns the total number of LP tokens staked.
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /// Returns the total number of LP tokens staked by a given address.
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    /// Returns the last time for which a rewards have already been earned.
    function lastTimeRewardApplicable() public view override returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    /// Returns the current amount of reward allocated per staked LP token.
    function rewardPerToken() public view override returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
            );
    }

    /// Returns the total reward earnings associated with a given address.
    function earned(address account) public view override returns (uint256) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    /// Returns the total reward amount.
    function getRewardForDuration() external view override returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /// Stake a number of LP tokens to earn rewards, using a signed permit instead of a balance approval.
    function stakeWithPermit(uint256 amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);

        // permit
        IUniswapV2ERC20(address(stakingToken)).permit(msg.sender, address(this), amount, deadline, v, r, s);

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    /// Stake a number of LP tokens to earn rewards.
    function stake(uint256 amount) external override nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    /// Withdraw a number of LP tokens.
    function withdraw(uint256 amount) public override nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    /// Transfer the caller's earned rewards.
    function getReward() public override nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    /// Withdraw all staked LP tokens and any pending rewards.
    function exit() external override {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /// Called by the StakingRewardsFactory to begin reward distribution.
    function notifyRewardAmount(uint256 reward) external override onlyRewardsDistribution updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance = rewardsToken.balanceOf(address(this));
        require(rewardRate <= balance.div(rewardsDuration), "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /* ========== EVENTS ========== */

    /// Emitted when the StakingRewardsFactory has allocated a reward balance to a StakingRewards contract, starting the staking period.
    event RewardAdded(uint256 reward);
    /// Emitted when a user stakes their LP tokens.
    event Staked(address indexed user, uint256 amount);
    /// Emitted when a user withdraws their LP tokens.
    event Withdrawn(address indexed user, uint256 amount);
    /// Emitted when a user has been paid a reward.
    event RewardPaid(address indexed user, uint256 reward);
}

interface IUniswapV2ERC20 {
    /// Allows a user to permit a contract to access their tokens by signing a permit.
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}