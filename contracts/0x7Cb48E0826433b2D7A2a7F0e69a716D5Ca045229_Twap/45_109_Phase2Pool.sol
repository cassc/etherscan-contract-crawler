// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "synthetix/contracts/interfaces/IStakingRewards.sol";

import "./RewardDistributionRecipient.sol";

/**
 * @title Phase 2 BANK Reward Pool for Float Protocol
 * @notice This contract is used to reward `rewardToken` when `stakeToken` is staked.
 */
contract Phase2Pool is
  IStakingRewards,
  Context,
  AccessControl,
  RewardDistributionRecipient,
  ReentrancyGuard
{
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /* ========== CONSTANTS ========== */
  uint256 public constant DURATION = 7 days;
  bytes32 public constant RECOVER_ROLE = keccak256("RECOVER_ROLE");

  /* ========== STATE VARIABLES ========== */
  IERC20 public rewardToken;
  IERC20 public stakeToken;

  uint256 public periodFinish = 0;
  uint256 public rewardRate = 0;
  uint256 public lastUpdateTime;
  uint256 public rewardPerTokenStored;

  mapping(address => uint256) public userRewardPerTokenPaid;
  mapping(address => uint256) public rewards;

  uint256 private _totalSupply;
  mapping(address => uint256) private _balances;

  /* ========== CONSTRUCTOR ========== */

  /**
   * @notice Construct a new Phase2Pool
   * @param _admin The default role controller for
   * @param _rewardDistribution The reward distributor (can change reward rate)
   * @param _rewardToken The reward token to distribute
   * @param _stakingToken The staking token used to qualify for rewards
   */
  constructor(
    address _admin,
    address _rewardDistribution,
    address _rewardToken,
    address _stakingToken
  ) RewardDistributionRecipient(_admin) {
    rewardDistribution = _rewardDistribution;
    rewardToken = IERC20(_rewardToken);
    stakeToken = IERC20(_stakingToken);

    _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    _setupRole(RECOVER_ROLE, _admin);
  }

  /* ========== EVENTS ========== */

  event RewardAdded(uint256 reward);
  event Staked(address indexed user, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount);
  event RewardPaid(address indexed user, uint256 reward);
  event Recovered(address token, uint256 amount);

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

  /* ========== VIEWS ========== */

  function totalSupply()
    public
    view
    override(IStakingRewards)
    returns (uint256)
  {
    return _totalSupply;
  }

  function balanceOf(address account)
    public
    view
    override(IStakingRewards)
    returns (uint256)
  {
    return _balances[account];
  }

  function lastTimeRewardApplicable()
    public
    view
    override(IStakingRewards)
    returns (uint256)
  {
    return Math.min(block.timestamp, periodFinish);
  }

  function rewardPerToken()
    public
    view
    override(IStakingRewards)
    returns (uint256)
  {
    if (totalSupply() == 0) {
      return rewardPerTokenStored;
    }

    return
      rewardPerTokenStored.add(
        lastTimeRewardApplicable()
          .sub(lastUpdateTime)
          .mul(rewardRate)
          .mul(1e18)
          .div(totalSupply())
      );
  }

  function earned(address account)
    public
    view
    override(IStakingRewards)
    returns (uint256)
  {
    return
      balanceOf(account)
        .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
        .div(1e18)
        .add(rewards[account]);
  }

  function getRewardForDuration()
    external
    view
    override(IStakingRewards)
    returns (uint256)
  {
    return rewardRate.mul(DURATION);
  }

  /* ========== MUTATIVE FUNCTIONS ========== */
  function stake(uint256 amount)
    public
    virtual
    override(IStakingRewards)
    updateReward(msg.sender)
  {
    require(amount > 0, "Phase2Pool::stake: Cannot stake 0");

    _totalSupply = _totalSupply.add(amount);
    _balances[msg.sender] = _balances[msg.sender].add(amount);

    stakeToken.safeTransferFrom(msg.sender, address(this), amount);
    emit Staked(msg.sender, amount);
  }

  function withdraw(uint256 amount)
    public
    override(IStakingRewards)
    updateReward(msg.sender)
  {
    require(amount > 0, "Phase2Pool::withdraw: Cannot withdraw 0");
    _totalSupply = _totalSupply.sub(amount);
    _balances[msg.sender] = _balances[msg.sender].sub(amount);
    stakeToken.safeTransfer(msg.sender, amount);
    emit Withdrawn(msg.sender, amount);
  }

  function exit() external override(IStakingRewards) {
    withdraw(balanceOf(msg.sender));
    getReward();
  }

  function getReward()
    public
    virtual
    override(IStakingRewards)
    updateReward(msg.sender)
  {
    uint256 reward = earned(msg.sender);
    if (reward > 0) {
      rewards[msg.sender] = 0;
      rewardToken.safeTransfer(msg.sender, reward);
      emit RewardPaid(msg.sender, reward);
    }
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  /* ----- Reward Distributor ----- */

  /**
   * @notice Should be called after the amount of reward tokens has
     been sent to the contract.
     Reward should be divisible by duration.
   * @param reward number of tokens to be distributed over the duration.
   */
  function notifyRewardAmount(uint256 reward)
    external
    override
    onlyRewardDistribution
    updateReward(address(0))
  {
    if (block.timestamp >= periodFinish) {
      rewardRate = reward.div(DURATION);
    } else {
      uint256 remaining = periodFinish.sub(block.timestamp);
      uint256 leftover = remaining.mul(rewardRate);
      rewardRate = reward.add(leftover).div(DURATION);
    }

    // Ensure provided reward amount is not more than the balance in the contract.
    // Keeps reward rate within the right range to prevent overflows in earned or rewardsPerToken
    // Reward + leftover < 1e18
    uint256 balance = rewardToken.balanceOf(address(this));
    require(
      rewardRate <= balance.div(DURATION),
      "Phase2Pool::notifyRewardAmount: Insufficent balance for reward rate"
    );

    lastUpdateTime = block.timestamp;
    periodFinish = block.timestamp.add(DURATION);
    emit RewardAdded(reward);
  }

  /* ----- RECOVER_ROLE ----- */

  /**
   * @notice Provide accidental token retrieval.
   * @dev Sourced from synthetix/contracts/StakingRewards.sol
   */
  function recoverERC20(address tokenAddress, uint256 tokenAmount) external {
    require(
      hasRole(RECOVER_ROLE, _msgSender()),
      "Phase2Pool::recoverERC20: You must possess the recover role to recover erc20"
    );
    require(
      tokenAddress != address(stakeToken),
      "Phase2Pool::recoverERC20: Cannot recover the staking token"
    );
    require(
      tokenAddress != address(rewardToken),
      "Phase2Pool::recoverERC20: Cannot recover the reward token"
    );

    IERC20(tokenAddress).safeTransfer(_msgSender(), tokenAmount);
    emit Recovered(tokenAddress, tokenAmount);
  }
}