/// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IStakingRewards.sol";
import "../interfaces/IRewardsEscrow.sol";

// https://docs.synthetix.io/contracts/source/contracts/stakingrewards
contract Staking is IStakingRewards, Ownable, ReentrancyGuard, Pausable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /* ========== STATE VARIABLES ========== */

  IERC20 public rewardsToken;
  IERC20 public stakingToken;
  IRewardsEscrow public rewardsEscrow;
  uint256 public periodFinish = 0;
  uint256 public rewardRate = 0;
  uint256 public rewardsDuration = 7 days;
  uint256 public lastUpdateTime;
  uint256 public rewardPerTokenStored;

  // duration in seconds for rewards to be held in escrow
  uint256 public escrowDuration;

  mapping(address => uint256) public userRewardPerTokenPaid;
  mapping(address => uint256) public rewards;
  mapping(address => bool) public rewardDistributors;

  uint256 private _totalSupply;
  mapping(address => uint256) private _balances;

  /* ========== CONSTRUCTOR ========== */

  constructor(
    IERC20 _rewardsToken,
    IERC20 _stakingToken,
    IRewardsEscrow _rewardsEscrow
  ) {
    rewardsToken = _rewardsToken;
    stakingToken = _stakingToken;
    rewardsEscrow = _rewardsEscrow;
    rewardDistributors[msg.sender] = true;
    escrowDuration = 365 days;

    _rewardsToken.safeIncreaseAllowance(address(_rewardsEscrow), type(uint256).max);
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
    return
      rewardPerTokenStored.add(
        lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
      );
  }

  function earned(address account) public view override returns (uint256) {
    return
      _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
  }

  function getRewardForDuration() external view override returns (uint256) {
    return rewardRate.mul(rewardsDuration);
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  function stakeFor(uint256 amount, address account) external {
    _stake(amount, account);
  }

  function stake(uint256 amount) external override {
    _stake(amount, msg.sender);
  }

  function _stake(uint256 amount, address account) internal nonReentrant whenNotPaused updateReward(account) {
    require(amount > 0, "Cannot stake 0");
    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    stakingToken.safeTransferFrom(msg.sender, address(this), amount);
    emit Staked(account, amount);
  }

  function withdraw(uint256 amount) public override nonReentrant updateReward(msg.sender) {
    require(amount > 0, "Cannot withdraw 0");
    _totalSupply = _totalSupply.sub(amount);
    _balances[msg.sender] = _balances[msg.sender].sub(amount);
    stakingToken.safeTransfer(msg.sender, amount);
    emit Withdrawn(msg.sender, amount);
  }

  function getReward() public override nonReentrant updateReward(msg.sender) {
    uint256 reward = rewards[msg.sender];
    if (reward > 0) {
      rewards[msg.sender] = 0;
      uint256 payout = reward / uint256(10);
      uint256 escrowed = payout * uint256(9);

      rewardsToken.safeTransfer(msg.sender, payout);
      rewardsEscrow.lock(msg.sender, escrowed, escrowDuration);
      emit RewardPaid(msg.sender, reward);
    }
  }

  function exit() external override {
    withdraw(_balances[msg.sender]);
    getReward();
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  function setEscrowDuration(uint256 duration) external onlyOwner {
    emit EscrowDurationUpdated(escrowDuration, duration);
    escrowDuration = duration;
  }

  function notifyRewardAmount(uint256 reward) external override updateReward(address(0)) {
    require(rewardDistributors[msg.sender], "not authorized");

    if (block.timestamp >= periodFinish) {
      rewardRate = reward.div(rewardsDuration);
    } else {
      uint256 remaining = periodFinish.sub(block.timestamp);
      uint256 leftover = remaining.mul(rewardRate);
      rewardRate = reward.add(leftover).div(rewardsDuration);
    }

    // handle the transfer of reward tokens via `transferFrom` to reduce the number
    // of transactions required and ensure correctness of the reward amount
    IERC20(rewardsToken).safeTransferFrom(msg.sender, address(this), reward);

    // Ensure the provided reward amount is not more than the balance in the contract.
    // This keeps the reward rate in the right range, preventing overflows due to
    // very high values of rewardRate in the earned and rewardsPerToken functions;
    // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
    uint256 balance = rewardsToken.balanceOf(address(this));
    require(rewardRate <= balance.div(rewardsDuration), "Provided reward too high");

    lastUpdateTime = block.timestamp;
    periodFinish = block.timestamp.add(rewardsDuration);

    emit RewardAdded(reward);
  }

  // Modify approval for an address to call notifyRewardAmount
  function approveRewardDistributor(address _distributor, bool _approved) external onlyOwner {
    emit RewardDistributorUpdated(_distributor, _approved);
    rewardDistributors[_distributor] = _approved;
  }

  // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
  function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
    require(tokenAddress != address(stakingToken), "Cannot withdraw the staking token");
    require(tokenAddress != address(rewardsToken), "Cannot withdraw the rewards token");
    IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
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

  function setRewardsEscrow(address _rewardsEscrow) external onlyOwner {
    emit RewardsEscrowUpdated(address(rewardsEscrow), _rewardsEscrow);
    rewardsEscrow = IRewardsEscrow(_rewardsEscrow);
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
  event RewardsEscrowUpdated(address _previous, address _new);
  event Withdrawn(address indexed user, uint256 amount);
  event RewardPaid(address indexed user, uint256 reward);
  event RewardsDurationUpdated(uint256 newDuration);
  event EscrowDurationUpdated(uint256 _previousDuration, uint256 _newDuration);
  event Recovered(address token, uint256 amount);
  event RewardDistributorUpdated(address indexed distributor, bool approved);
}