// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "synthetix/contracts/interfaces/IStakingRewards.sol";

import "./RewardDistributionRecipient.sol";

/**
 * @title Base Reward Pool for Float Protocol
 * @notice This contract is used to reward `rewardToken` when `stakeToken` is staked.
 * @dev The Pools are based on the original Synthetix rewards contract (https://etherscan.io/address/0xDCB6A51eA3CA5d3Fd898Fd6564757c7aAeC3ca92#code) developed by @k06a which is battled tested and widely used.
 * Alterations:
 * - duration set on constructor (immutable)
 * - Internal properties rather than private
 * - Add virtual marker to functions
 * - Change stake / withdraw to external and provide internal equivalents
 * - Change require messages to match convention
 * - Add hooks for _beforeWithdraw and _beforeStake
 * - Emit events before external calls in line with best practices.
 */
abstract contract BasePool is
  IStakingRewards,
  AccessControl,
  RewardDistributionRecipient
{
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /* ========== CONSTANTS ========== */
  bytes32 public constant RECOVER_ROLE = keccak256("RECOVER_ROLE");
  uint256 public immutable duration;

  /* ========== STATE VARIABLES ========== */
  IERC20 public rewardToken;
  IERC20 public stakeToken;

  uint256 public periodFinish;
  uint256 public rewardRate;
  uint256 public lastUpdateTime;
  uint256 public rewardPerTokenStored;

  mapping(address => uint256) public userRewardPerTokenPaid;
  mapping(address => uint256) public rewards;

  uint256 internal _totalSupply;
  mapping(address => uint256) internal _balances;

  /* ========== CONSTRUCTOR ========== */

  /**
   * @notice Construct a new BasePool
   * @param _admin The default role controller
   * @param _rewardDistribution The reward distributor (can change reward rate)
   * @param _rewardToken The reward token to distribute
   * @param _stakingToken The staking token used to qualify for rewards
   */
  constructor(
    address _admin,
    address _rewardDistribution,
    address _rewardToken,
    address _stakingToken,
    uint256 _duration
  ) RewardDistributionRecipient(_admin) {
    rewardDistribution = _rewardDistribution;
    rewardToken = IERC20(_rewardToken);
    stakeToken = IERC20(_stakingToken);

    duration = _duration;

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

  modifier updateReward(address account) virtual {
    rewardPerTokenStored = rewardPerToken();
    lastUpdateTime = lastTimeRewardApplicable();
    if (account != address(0)) {
      rewards[account] = earned(account);
      userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }
    _;
  }

  /* ========== VIEWS ========== */

  /**
   * @notice The total reward producing staked supply (total quantity to distribute)
   */
  function totalSupply()
    public
    view
    virtual
    override(IStakingRewards)
    returns (uint256)
  {
    return _totalSupply;
  }

  /**
   * @notice The total reward producing balance of the account.
   */
  function balanceOf(address account)
    public
    view
    virtual
    override(IStakingRewards)
    returns (uint256)
  {
    return _balances[account];
  }

  function lastTimeRewardApplicable()
    public
    view
    virtual
    override(IStakingRewards)
    returns (uint256)
  {
    return Math.min(block.timestamp, periodFinish);
  }

  function rewardPerToken()
    public
    view
    virtual
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
    virtual
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
    return rewardRate.mul(duration);
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  function stake(uint256 amount)
    external
    virtual
    override(IStakingRewards)
    updateReward(msg.sender)
  {
    require(amount > 0, "BasePool/NonZeroStake");

    _stake(msg.sender, msg.sender, amount);
  }

  function withdraw(uint256 amount)
    external
    virtual
    override(IStakingRewards)
    updateReward(msg.sender)
  {
    require(amount > 0, "BasePool/NonZeroWithdraw");

    _withdraw(msg.sender, amount);
  }

  /**
   * @notice Exit the pool, taking any rewards due and staked
   */
  function exit()
    external
    virtual
    override(IStakingRewards)
    updateReward(msg.sender)
  {
    _withdraw(msg.sender, _balances[msg.sender]);
    getReward();
  }

  /**
   * @notice Retrieve any rewards due
   */
  function getReward()
    public
    virtual
    override(IStakingRewards)
    updateReward(msg.sender)
  {
    uint256 reward = earned(msg.sender);
    if (reward > 0) {
      rewards[msg.sender] = 0;

      emit RewardPaid(msg.sender, reward);

      rewardToken.safeTransfer(msg.sender, reward);
    }
  }

  /**
   * @dev Stakes `amount` tokens from `staker` to `recipient`, increasing the total supply.
   *
   * Emits a {Staked} event.
   *
   * Requirements:
   * - `recipient` cannot be zero address.
   * - `staker` must have at least `amount` tokens
   * - `staker` must approve this contract for at least `amount`
   */
  function _stake(
    address staker,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(recipient != address(0), "BasePool/ZeroAddressS");

    _beforeStake(staker, recipient, amount);

    _totalSupply = _totalSupply.add(amount);
    _balances[recipient] = _balances[recipient].add(amount);

    emit Staked(recipient, amount);
    stakeToken.safeTransferFrom(staker, address(this), amount);
  }

  /**
   * @dev Withdraws `amount` tokens from `account`, reducing the total supply.
   *
   * Emits a {Withdrawn} event.
   *
   * Requirements:
   * - `account` cannot be zero address.
   * - `account` must have at least `amount` staked.
   */
  function _withdraw(address account, uint256 amount) internal virtual {
    require(account != address(0), "BasePool/ZeroAddressW");

    _beforeWithdraw(account, amount);

    _balances[account] = _balances[account].sub(
      amount,
      "BasePool/WithdrawExceedsBalance"
    );
    _totalSupply = _totalSupply.sub(amount);

    emit Withdrawn(account, amount);
    stakeToken.safeTransfer(account, amount);
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
    public
    virtual
    override
    onlyRewardDistribution
    updateReward(address(0))
  {
    if (block.timestamp >= periodFinish) {
      rewardRate = reward.div(duration);
    } else {
      uint256 remaining = periodFinish.sub(block.timestamp);
      uint256 leftover = remaining.mul(rewardRate);
      rewardRate = reward.add(leftover).div(duration);
    }

    // Ensure provided reward amount is not more than the balance in the contract.
    // Keeps reward rate within the right range to prevent overflows in earned or rewardsPerToken
    // Reward + leftover < 1e18
    uint256 balance = rewardToken.balanceOf(address(this));
    require(rewardRate <= balance.div(duration), "BasePool/InsufficentBalance");

    lastUpdateTime = block.timestamp;
    periodFinish = block.timestamp.add(duration);
    emit RewardAdded(reward);
  }

  /* ----- RECOVER_ROLE ----- */

  /**
   * @notice Provide accidental token retrieval.
   * @dev Sourced from synthetix/contracts/StakingRewards.sol
   */
  function recoverERC20(address tokenAddress, uint256 tokenAmount) external {
    require(hasRole(RECOVER_ROLE, _msgSender()), "BasePool/RecoverRole");
    require(tokenAddress != address(stakeToken), "BasePool/NoRecoveryOfStake");
    require(
      tokenAddress != address(rewardToken),
      "BasePool/NoRecoveryOfReward"
    );

    emit Recovered(tokenAddress, tokenAmount);

    IERC20(tokenAddress).safeTransfer(_msgSender(), tokenAmount);
  }

  /* ========== HOOKS ========== */

  /**
   * @dev Hook that is called before any staking of tokens.
   *
   * Calling conditions:
   *
   * - `amount` of ``staker``'s tokens will be staked into the pool
   * - `recipient` can withdraw.
   */
  function _beforeStake(
    address staker,
    address recipient,
    uint256 amount
  ) internal virtual {}

  /**
   * @dev Hook that is called before any staking of tokens.
   *
   * Calling conditions:
   *
   * - `amount` of ``from``'s tokens will be withdrawn into the pool
   */
  function _beforeWithdraw(address from, uint256 amount) internal virtual {}
}