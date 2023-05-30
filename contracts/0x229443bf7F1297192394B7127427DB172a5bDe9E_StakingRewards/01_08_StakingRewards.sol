// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Inheritance
import "./interfaces/IStakingRewards.sol";
import "./RewardsDistributionRecipient.sol";
import "./vendor/ReentrancyGuard.sol";
import "./Pausable.sol";

// Internal references
import "./Utils.sol";

// Original contract can be found under the following link:
// https://github.com/Synthetixio/synthetix/blob/master/contracts/StakingRewards.sol
contract StakingRewards is IStakingRewards, RewardsDistributionRecipient, ReentrancyGuard, Pausable {
    /* ========== STATE VARIABLES ========== */
    
    address immutable public rewardsToken;
    address immutable public stakingToken;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration = 14 days;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _owner,
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken
    ) Owned(_owner) {
        rewardsToken = _rewardsToken;
        stakingToken = _stakingToken;
        rewardsDistribution = _rewardsDistribution;
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view override returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function rewardPerToken() public view override returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored + ((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18 / _totalSupply);
    }

    function earned(address account) public view override returns (uint256) {
        return (_balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account]) / 1e18) + rewards[account];
    }

    function getRewardForDuration() external view override returns (uint256) {
        return rewardRate * rewardsDuration;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint subAccountId, uint256 amount) public override nonReentrant notPaused updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");

        address from = Utils.getSubAccount(msg.sender, subAccountId);
        _totalSupply = _totalSupply + amount;
        _balances[msg.sender] = _balances[msg.sender] + amount;
        
        Utils.safeTransferFrom(stakingToken, from, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint subAccountId, uint256 amount) public override nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");

        address to = Utils.getSubAccount(msg.sender, subAccountId);
        _totalSupply = _totalSupply - amount;
        _balances[msg.sender] = _balances[msg.sender] - amount;

        Utils.safeTransfer(stakingToken, to, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public override nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            Utils.safeTransfer(rewardsToken, msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit(uint subAccountId) public override {
        withdraw(subAccountId, _balances[msg.sender]);
        getReward();
    }

    function stake(uint256 amount) external override {
        stake(0, amount);
    }

    function withdraw(uint256 amount) public override {
        withdraw(0, amount);
    }

    function exit() external override {
        exit(0);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 reward) external override onlyRewardsDistribution updateReward(address(0)) {
        require(block.timestamp >= periodFinish, "Staking period not finished");

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        uint balance =  IERC20(rewardsToken).balanceOf(address(this));
        require(reward <= balance, "Provided reward too high");

        rewardRate = reward / rewardsDuration;
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + rewardsDuration;
        emit RewardAdded(reward);
    }

    // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAddress != address(stakingToken), "Cannot withdraw the staking token");
        Utils.safeTransfer(tokenAddress, owner, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(
            block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
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

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);
}