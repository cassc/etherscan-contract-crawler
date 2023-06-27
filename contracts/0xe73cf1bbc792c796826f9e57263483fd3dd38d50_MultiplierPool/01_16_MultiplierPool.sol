// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "synthetix/contracts/interfaces/IStakingRewards.sol";

import "../interfaces/multiplier/IMultiStake.sol";

import "./MultiplierMath.sol";
import "./FundablePool.sol";

/**
 * @title Multiplier Pool for Float Protocol
 * @dev The Multiplier Pool provides `rewardTokens` for `stakeTokens` with a
 * token-over-time distribution, with the function being equal to their
 * "stake-seconds" divided by the global "stake-seconds".
 * This is designed to align token distribution with long term stakers.
 * The longer the hold, the higher the proportion of the pool; and the higher
 * the multiplier.
 *
 * THIS DOES NOT WORK WITH FEE TOKENS / REBASING TOKENS - Use Token Geyser V2 instead.
 *
 * This contract was only possible due to a number of existing
 * open-source contracts including:
 * - The original [Synthetix rewards contract](https://etherscan.io/address/0xDCB6A51eA3CA5d3Fd898Fd6564757c7aAeC3ca92#code) developed by k06a
 * - Ampleforth's Token Geyser [V1](https://github.com/ampleforth/token-geyser) and [V2](https://github.com/ampleforth/token-geyser-v2)
 * - [GYSR.io Token Geyser](https://github.com/gysr-io/core)
 * - [Alchemist's Aludel](https://github.com/alchemistcoin/alchemist/tree/main/contracts/aludel)
 */
contract MultiplierPool is
  IMultiStake,
  AccessControl,
  MultiplierMath,
  FundablePool
{
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /* ========== CONSTANTS ========== */
  bytes32 public constant RECOVER_ROLE = keccak256("RECOVER_ROLE");
  bytes32 public constant ADJUSTER_ROLE = keccak256("ADJUSTER_ROLE");

  /* ========== STATE VARIABLES ========== */
  IERC20 public immutable stakeToken;

  IBonusScaling.BonusScaling public bonusScaling;

  uint256 public hardLockPeriod;

  uint256 public lastUpdateTime;

  /// @dev {cached} total staked
  uint256 internal _totalStaked;

  /// @dev {cached} total staked seconds
  uint256 internal _totalStakeSeconds;

  struct UserData {
    // [eD] {cached} total stake from individual stakes
    uint256 totalStake;
    Stake[] stakes;
  }

  mapping(address => UserData) internal _users;

  /* ========== CONSTRUCTOR ========== */

  /**
   * @notice Construct a new MultiplierPool
   * @param _admin The default role controller
   * @param _funder The reward distributor
   * @param _rewardToken The reward token to distribute
   * @param _stakingToken The staking token used to qualify for rewards
   * @param _bonusScaling The starting bonus scaling amount
   * @param _hardLockPeriod The period for a hard lock to apply (no unstake)
   */
  constructor(
    address _admin,
    address _funder,
    address _rewardToken,
    address _stakingToken,
    IBonusScaling.BonusScaling memory _bonusScaling,
    uint256 _hardLockPeriod
  ) FundablePool(_funder, _rewardToken) {
    stakeToken = IERC20(_stakingToken);
    bonusScaling = _bonusScaling;
    hardLockPeriod = _hardLockPeriod;

    _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    _setupRole(ADJUSTER_ROLE, _admin);
    _setupRole(RECOVER_ROLE, _admin);
  }

  /* ========== EVENTS ========== */

  event Staked(address indexed user, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount);
  event Recovered(address token, uint256 amount);

  /* ========== VIEWS ========== */

  /**
   * @notice The total reward producing staked supply (total quantity to distribute)
   */
  function totalSupply() public view virtual returns (uint256) {
    return _totalStaked;
  }

  function getUserData(address user)
    external
    view
    returns (UserData memory userData)
  {
    return _users[user];
  }

  function getCurrentTotalStakeSeconds() public view returns (uint256) {
    return getFutureTotalStakeSeconds(block.timestamp);
  }

  function getFutureTotalStakeSeconds(uint256 timestamp)
    public
    view
    returns (uint256 totalStakeSeconds)
  {
    totalStakeSeconds = calculateTotalStakeSeconds(
      _totalStaked,
      _totalStakeSeconds,
      lastUpdateTime,
      timestamp
    );
  }

  /**
   * @notice The total staked balance of the staker.
   */
  function balanceOf(address staker) public view virtual returns (uint256) {
    return _users[staker].totalStake;
  }

  function earned(address staker) external view virtual returns (uint256) {
    UnstakeOutput memory out =
      simulateUnstake(
        _users[staker].stakes,
        balanceOf(staker),
        getCurrentTotalStakeSeconds(),
        unlockedRewardAmount().add(pendingRewardAmount(block.timestamp)),
        block.timestamp,
        bonusScaling
      );
    return out.rewardDue;
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  /**
   * @notice Stakes `amount` tokens from `msg.sender`
   *
   * Emits a {Staked} event.
   * Can emit a {RewardsUnlocked} event if additional rewards are now available.
   */
  function stake(uint256 amount) external virtual {
    _update();
    _stakeFor(msg.sender, msg.sender, amount);
  }

  /**
   * @notice Stakes `amount` tokens from `msg.sender` on behalf of `staker`
   *
   * Emits a {Staked} event.
   * Can emit a {RewardsUnlocked} event if additional rewards are now available.
   */
  function stakeFor(address staker, uint256 amount) external virtual {
    _update();
    _stakeFor(msg.sender, staker, amount);
  }

  /**
   * @notice Withdraw an `amount` from the pool including any rewards due for that stake
   *
   * Emits a {Withdrawn} event.
   * Can emit a {RewardsPaid} event if due rewards.
   * Can emit a {RewardsUnlocked} event if additional rewards are now available.
   */
  function withdraw(uint256 amount) external virtual {
    _update();
    _unstake(msg.sender, amount);
  }

  /**
   * @notice Exit the pool, taking any rewards due and any staked tokens
   *
   * Emits a {Withdrawn} event.
   * Can emit a {RewardsPaid} event if due rewards.
   * Can emit a {RewardsUnlocked} event if additional rewards are now available.
   */
  function exit() external virtual {
    _update();
    _unstake(msg.sender, balanceOf(msg.sender));
  }

  /**
   * @notice Retrieve any rewards due to `msg.sender`
   *
   * Can emit a {RewardsPaid} event if due rewards.
   * Can emit a {RewardsUnlocked} event if additional rewards are now available.
   *
   * Requirements:
   * - `msg.sender` must have some tokens staked
   */
  function getReward() external virtual {
    _update();
    address staker = msg.sender;
    uint256 totalStake = balanceOf(staker);
    uint256 reward = _unstakeAccounting(staker, totalStake);
    _stakeAccounting(staker, totalStake);

    if (reward != 0) {
      _distributeRewards(staker, reward);
    }
  }

  /**
   * @dev Stakes `amount` tokens from `payer` to `staker`, increasing the total supply.
   *
   * Emits a {Staked} event.
   *
   * Requirements:
   * - `staker` cannot be zero address.
   * - `payer` must have at least `amount` tokens
   * - `payer` must approve this contract for at least `amount`
   */
  function _stakeFor(
    address payer,
    address staker,
    uint256 amount
  ) internal virtual {
    require(staker != address(0), "MultiplierPool/ZeroAddressS");
    require(amount != 0, "MultiplierPool/NoAmount");

    _beforeStake(payer, staker, amount);

    _stakeAccounting(staker, amount);

    emit Staked(staker, amount);
    stakeToken.safeTransferFrom(payer, address(this), amount);
  }

  /**
   * @dev Withdraws `amount` tokens from `staker`, reducing the total supply.
   *
   * Emits a {Withdrawn} event.
   *
   * Requirements:
   * - `staker` cannot be zero address.
   * - `staker` must have at least `amount` staked.
   */
  function _unstake(address staker, uint256 amount) internal virtual {
    // Sense check input
    require(staker != address(0), "MultiplierPool/ZeroAddressW");
    require(amount != 0, "MultiplierPool/NoAmount");

    _beforeWithdraw(staker, amount);

    uint256 reward = _unstakeAccounting(staker, amount);

    if (reward != 0) {
      _distributeRewards(staker, reward);
    }

    emit Withdrawn(staker, amount);
    stakeToken.safeTransfer(staker, amount);
  }

  /**
   * @dev Performs necessary accounting for unstake operation
   * Assumes:
   * - `staker` is a valid address
   * - `amount` is non-zero
   * - `_update` has been called (and hence `_totalStakeSeconds` / `lockedRewardAmount` / `lastUpdateTime`)
   * - `rewardDue` will be transfered to `staker` after accounting
   * - `amount` will be transfered back to `staker` after accounting
   * - `Withdraw` / `RewardsPaid` will be emitted
   *
   * State:
   * - `_users[staker].stakes` will remove entries necessary to cover amount
   * - `_users[staker].totalStake` will be decreased
   * - `_totalStaked` will be reduced by amount
   * - `_totalStakeSeconds` will be reduced by unstaked stake seconds
   * @param staker Staker address to unstake from
   * @param amount Stake Tokens to be unstaked
   */
  function _unstakeAccounting(address staker, uint256 amount)
    internal
    virtual
    returns (uint256 rewardDue)
  {
    // Fetch User storage reference
    UserData storage userData = _users[staker];

    require(userData.totalStake >= amount, "MultiplierPool/ExceedsStake");
    // {cached} value would be de-synced
    assert(_totalStaked >= amount);

    UnstakeOutput memory out =
      simulateUnstake(
        userData.stakes,
        amount,
        getCurrentTotalStakeSeconds(),
        unlockedRewardAmount(),
        block.timestamp,
        bonusScaling
      );

    // Update storage data
    if (out.newStakesCount == 0) {
      delete userData.stakes;
    } else {
      // Remove all fully unstaked amounts
      while (userData.stakes.length > out.newStakesCount) {
        userData.stakes.pop();
      }

      if (out.lastStakeAmount != 0) {
        userData.stakes[out.newStakesCount.sub(1)].amount = out.lastStakeAmount;
      }
    }

    // Update {cached} totals
    userData.totalStake = userData.totalStake.sub(amount);
    _totalStaked = _totalStaked.sub(amount);
    _totalStakeSeconds = out.newTotalStakeSeconds;

    // Calculate rewards
    rewardDue = out.rewardDue;
  }

  /**
   * @dev Performs necessary accounting for stake operation
   * Assumes:
   * - `staker` is a valid address
   * - `amount` is non-zero
   * - `_update` has been called (and hence `_totalStakeSeconds` / `lockedRewardAmount` / `lastUpdateTime` are modified)
   * - `amount` has been transfered to the contract
   *
   * State:
   * - `_users[staker].stakes` will add a new entry for amount
   * - `_users[staker].totalStake` will be increased
   * - `_totalStaked` will be increased by amount
   * @param staker Staker address to stake for
   * @param amount Stake tokens to be staked
   */
  function _stakeAccounting(address staker, uint256 amount) internal {
    UserData storage userData = _users[staker];

    // Add new stake entry
    userData.stakes.push(Stake(amount, block.timestamp));

    // Update {cached} totals
    _totalStaked = _totalStaked.add(amount);
    userData.totalStake = userData.totalStake.add(amount);
  }

  /**
   * @dev Updates the Pool to:
   * - Releases token rewards for the current timestamp
   * - Updates the `_totalStakeSeconds` for the entire `_totalStake`
   * - Set `lastUpdateTime` to be block.timestamp
   */
  function _update() internal {
    _unlockRewards();

    _totalStakeSeconds = _totalStakeSeconds.add(
      calculateStakeSeconds(_totalStaked, lastUpdateTime, block.timestamp)
    );
    lastUpdateTime = block.timestamp;
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  /* ----- FUNDER_ROLE ----- */

  /**
   * @notice Fund pool by locking up reward tokens for future distribution
   * @param amount number of reward tokens to lock up as funding
   * @param duration period (seconds) over which funding will be unlocked
   * @param start time (seconds) at which funding begins to unlock
   */
  function fund(
    uint256 amount,
    uint256 duration,
    uint256 start
  ) external onlyFunder {
    _update();
    if (rewardToken == stakeToken) {
      uint256 allowed =
        rewardToken.balanceOf(address(this)).sub(totalRewardAmount).sub(
          _totalStaked
        );

      require(allowed >= amount, "FundablePool/InsufficentBalance");
    }
    _fund(amount, duration, start);
  }

  /**
   * @notice Clean a pool by expiring old rewards
   */
  function clean() external onlyFunder {
    _cleanRewardSchedules();
  }

  /* ----- ADJUSTER_ROLE ----- */
  /**
   * @notice Modify the bonus scaling once started
   * @dev Adjusters should be timelocked.
   * @param _bonusScaling Bonus Scaling parameters (min, max, period)
   */
  function modifyBonusScaling(BonusScaling memory _bonusScaling) external {
    require(hasRole(ADJUSTER_ROLE, msg.sender), "MultiplierPool/AdjusterRole");
    bonusScaling = _bonusScaling;
  }

  /**
   * @notice Modify the hard lock (allows release after a set period)
   * @dev Adjusters should be timelocked.
   * @param _hardLockPeriod [seconds] length of time to refuse release of staked funds
   */
  function modifyHardLock(uint256 _hardLockPeriod) external {
    require(hasRole(ADJUSTER_ROLE, msg.sender), "MultiplierPool/AdjusterRole");
    hardLockPeriod = _hardLockPeriod;
  }

  /* ----- RECOVER_ROLE ----- */

  /**
   * @notice Provide accidental token retrieval.
   * @dev Sourced from synthetix/contracts/StakingRewards.sol
   */
  function recoverERC20(address tokenAddress, uint256 tokenAmount) external {
    require(hasRole(RECOVER_ROLE, msg.sender), "MultiplierPool/RecoverRole");
    require(
      tokenAddress != address(stakeToken),
      "MultiplierPool/NoRecoveryOfStake"
    );
    require(
      tokenAddress != address(rewardToken),
      "MultiplierPool/NoRecoveryOfReward"
    );

    emit Recovered(tokenAddress, tokenAmount);

    IERC20(tokenAddress).safeTransfer(msg.sender, tokenAmount);
  }

  /* ========== HOOKS ========== */

  /**
   * @dev Hook that is called before any staking of tokens.
   *
   * Calling conditions:
   *
   * - `amount` of `payer`'s tokens will be staked into the pool
   * - `staker` can withdraw.
   * N.B. this is not called on claiming rewards
   */
  function _beforeStake(
    address payer,
    address staker,
    uint256 amount
  ) internal virtual {}

  /**
   * @dev Hook that is called before any withdrawal of tokens.
   *
   * Calling conditions:
   *
   * - `amount` of ``from``'s tokens will be withdrawn into the pool
   * N.B. this is not called on claiming rewards
   */
  function _beforeWithdraw(address from, uint256) internal virtual {
    // Check hard lock - was the last stake > hardLockPeriod
    Stake[] memory userStakes = _users[from].stakes;
    Stake memory lastStake = userStakes[userStakes.length.sub(1)];
    require(
      lastStake.timestamp.add(hardLockPeriod) <= block.timestamp,
      "MultiplierPool/HardLockNotPassed"
    );
  }
}