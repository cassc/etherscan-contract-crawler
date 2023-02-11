// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;
pragma abicoder v2;

import { SafeMathUpgradeable } from '@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol';
import { IERC20Upgradeable } from '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import { LS1Types } from '../lib/LS1Types.sol';
import { SafeCast } from '../lib/SafeCast.sol';
import { LS1Rewards } from './LS1Rewards.sol';

/**
 * @title LS1StakedBalances
 * @author MarginX
 *
 * @dev Accounting of staked balances.
 *
 *  NOTE: Internal functions may revert if epoch zero has not started.
 *
 *  STAKED BALANCE ACCOUNTING:
 *
 *   A staked balance is in one of two states:
 *     - active: Available for borrowing; earning staking rewards; cannot be withdrawn by staker.
 *     - inactive: Unavailable for borrowing; does not earn rewards; can be withdrawn by the staker.
 *
 *   A staker may have a combination of active and inactive balances. The following operations
 *   affect staked balances as follows:
 *     - deposit:            Increase active balance.
 *     - request withdrawal: At the end of the current epoch, move some active funds to inactive.
 *     - withdraw:           Decrease inactive balance.
 *     - transfer:           Move some active funds to another staker.
 *
 *   To encode the fact that a balance may be scheduled to change at the end of a certain epoch, we
 *   store each balance as a struct of three fields: currentEpoch, currentEpochBalance, and
 *   nextEpochBalance. Also, inactive user balances make use of the shortfallCounter field as
 *   described below.
 *
 *  INACTIVE BALANCE ACCOUNTING:
 *
 *   Inactive funds may be subject to pro-rata socialized losses in the event of a shortfall where
 *   a borrower is late to pay back funds that have been requested for withdrawal. We track losses
 *   via indexes. Each index represents the fraction of inactive funds that were converted into
 *   debt during a given shortfall event. Each staker inactive balance stores a cached shortfall
 *   counter, representing the number of shortfalls that occurred in the past relative to when the
 *   balance was last updated.
 *
 *   Any losses incurred by an inactive balance translate into an equal credit to that staker's
 *   debt balance. See LS1DebtAccounting for more info about how the index is calculated.
 *
 *  REWARDS ACCOUNTING:
 *
 *   Active funds earn rewards for the period of time that they remain active. This means, after
 *   requesting a withdrawal of some funds, those funds will continue to earn rewards until the end
 *   of the epoch. For example:
 *
 *     epoch: n        n + 1      n + 2      n + 3
 *            |          |          |          |
 *            +----------+----------+----------+-----...
 *               ^ t_0: User makes a deposit.
 *                          ^ t_1: User requests a withdrawal of all funds.
 *                                  ^ t_2: The funds change state from active to inactive.
 *
 *   In the above scenario, the user would earn rewards for the period from t_0 to t_2, varying
 *   with the total staked balance in that period. If the user only request a withdrawal for a part
 *   of their balance, then the remaining balance would continue earning rewards beyond t_2.
 *
 *   User rewards must be settled via LS1Rewards any time a user's active balance changes. Special
 *   attention is paid to the the epoch boundaries, where funds may have transitioned from active
 *   to inactive.
 *
 *  SETTLEMENT DETAILS:
 *
 *   Internally, this module uses the following types of operations on stored balances:
 *     - Load:            Loads a balance, while applying settlement logic internally to get the
 *                        up-to-date result. Returns settlement results without updating state.
 *     - Store:           Stores a balance.
 *     - Load-for-update: Performs a load and applies updates as needed to rewards or debt balances.
 *                        Since this is state-changing, it must be followed by a store operation.
 *     - Settle:          Performs load-for-update and store operations.
 *
 *   This module is responsible for maintaining the following invariants to ensure rewards are
 *   calculated correctly:
 *     - When an active balance is loaded for update, if a rollover occurs from one epoch to the
 *       next, the rewards index must be settled up to the boundary at which the rollover occurs.
 *     - Because the global rewards index is needed to update the user rewards index, the total
 *       active balance must be settled before any staker balances are settled or loaded for update.
 *     - A staker's balance must be settled before their rewards are settled.
 */
abstract contract LS1StakedBalances is
  LS1Rewards
{
  using SafeCast for uint256;
  using SafeMathUpgradeable for uint256;

  // ============ Constants ============

  uint256 internal constant SHORTFALL_INDEX_BASE = 1e36;

  // ============ Events ============

  event ReceivedDebt(
    address indexed staker,
    uint256 amount,
    uint256 newDebtBalance
  );

  // ============ Public Functions ============

  /**
   * @notice Get the current active balance of a staker.
   */
  function getActiveBalanceCurrentEpoch(
    address staker
  )
    public
    view
    returns (uint256)
  {
    if (!hasEpochZeroStarted()) {
      return 0;
    }
    (LS1Types.StoredBalance memory balance, , , ) = _loadActiveBalance(_ACTIVE_BALANCES_[staker]);
    return uint256(balance.currentEpochBalance);
  }

  /**
   * @notice Get the next epoch active balance of a staker.
   */
  function getActiveBalanceNextEpoch(
    address staker
  )
    public
    view
    returns (uint256)
  {
    if (!hasEpochZeroStarted()) {
      return 0;
    }
    (LS1Types.StoredBalance memory balance, , , ) = _loadActiveBalance(_ACTIVE_BALANCES_[staker]);
    return uint256(balance.nextEpochBalance);
  }

  /**
   * @notice Get the current total active balance.
   */
  function getTotalActiveBalanceCurrentEpoch()
    public
    view
    returns (uint256)
  {
    if (!hasEpochZeroStarted()) {
      return 0;
    }
    (LS1Types.StoredBalance memory balance, , , ) = _loadActiveBalance(_TOTAL_ACTIVE_BALANCE_);
    return uint256(balance.currentEpochBalance);
  }

  /**
   * @notice Get the next epoch total active balance.
   */
  function getTotalActiveBalanceNextEpoch()
    public
    view
    returns (uint256)
  {
    if (!hasEpochZeroStarted()) {
      return 0;
    }
    (LS1Types.StoredBalance memory balance, , , ) = _loadActiveBalance(_TOTAL_ACTIVE_BALANCE_);
    return uint256(balance.nextEpochBalance);
  }

  /**
   * @notice Get the current inactive balance of a staker.
   * @dev The balance is converted via the index to token units.
   */
  function getInactiveBalanceCurrentEpoch(
    address staker
  )
    public
    view
    returns (uint256)
  {
    if (!hasEpochZeroStarted()) {
      return 0;
    }
    (LS1Types.StoredBalance memory balance, ) =
      _loadUserInactiveBalance(_INACTIVE_BALANCES_[staker]);
    return uint256(balance.currentEpochBalance);
  }

  /**
   * @notice Get the next epoch inactive balance of a staker.
   * @dev The balance is converted via the index to token units.
   */
  function getInactiveBalanceNextEpoch(
    address staker
  )
    public
    view
    returns (uint256)
  {
    if (!hasEpochZeroStarted()) {
      return 0;
    }
    (LS1Types.StoredBalance memory balance, ) =
      _loadUserInactiveBalance(_INACTIVE_BALANCES_[staker]);
    return uint256(balance.nextEpochBalance);
  }

  /**
   * @notice Get the current total inactive balance.
   */
  function getTotalInactiveBalanceCurrentEpoch()
    public
    view
    returns (uint256)
  {
    if (!hasEpochZeroStarted()) {
      return 0;
    }
    LS1Types.StoredBalance memory balance = _loadTotalInactiveBalance(_TOTAL_INACTIVE_BALANCE_);
    return uint256(balance.currentEpochBalance);
  }

  /**
   * @notice Get the next epoch total inactive balance.
   */
  function getTotalInactiveBalanceNextEpoch()
    public
    view
    returns (uint256)
  {
    if (!hasEpochZeroStarted()) {
      return 0;
    }
    LS1Types.StoredBalance memory balance = _loadTotalInactiveBalance(_TOTAL_INACTIVE_BALANCE_);
    return uint256(balance.nextEpochBalance);
  }

  /**
   * @notice Get a staker's debt balance, after accounting for unsettled shortfalls.
   *  Note that this does not modify _STAKER_DEBT_BALANCES_, so the debt balance must still be
   *  settled before it can be withdrawn.
   *
   * @param  staker  The staker to get the balance of.
   *
   * @return The settled debt balance.
   */
  function getStakerDebtBalance(
    address staker
  )
    public
    view
    returns (uint256)
  {
    if (!hasEpochZeroStarted()) {
      return 0;
    }
    (, uint256 newDebtAmount) = _loadUserInactiveBalance(_INACTIVE_BALANCES_[staker]);
    return _STAKER_DEBT_BALANCES_[staker].add(newDebtAmount);
  }

  /**
   * @notice Get the current transferable balance for a user. The user can
   *  only transfer their balance that is not currently inactive or going to be
   *  inactive in the next epoch. Note that this means the user's transferable funds
   *  are their active balance of the next epoch.
   *
   * @param  account  The account to get the transferable balance of.
   *
   * @return The user's transferable balance.
   */
  function getTransferableBalance(
    address account
  )
    public
    view
    returns (uint256)
  {
    return getActiveBalanceNextEpoch(account);
  }


  // ============ External Functions ============


  // ============ Internal Functions ============

  function _increaseCurrentAndNextActiveBalance(
    address staker,
    uint256 amount
  )
    internal
  {
    // Always settle total active balance before settling a staker active balance.
    uint256 oldTotalBalance = _increaseCurrentAndNextBalances(address(0), true, amount);
    uint256 oldUserBalance = _increaseCurrentAndNextBalances(staker, true, amount);

    // When an active balance changes at current timestamp, settle rewards to the current timestamp.
    _settleUserRewardsUpToNow(staker, oldUserBalance, oldTotalBalance);
  }

  function _moveNextBalanceActiveToInactive(
    address staker,
    uint256 amount
  )
    internal
  {
    // Decrease the active balance for the next epoch.
    // Always settle total active balance before settling a staker active balance.
    _decreaseNextBalance(address(0), true, amount);
    _decreaseNextBalance(staker, true, amount);

    // Increase the inactive balance for the next epoch.
    _increaseNextBalance(address(0), false, amount);
    _increaseNextBalance(staker, false, amount);

    // Note that we don't need to settle rewards since the current active balance did not change.
  }

  function _transferCurrentAndNextActiveBalance(
    address sender,
    address recipient,
    uint256 amount
  )
    internal
  {
    // Always settle total active balance before settling a staker active balance.
    uint256 totalBalance = _settleTotalActiveBalance();

    // Move current and next active balances from sender to recipient.
    uint256 oldSenderBalance = _decreaseCurrentAndNextBalances(sender, true, amount);
    uint256 oldRecipientBalance = _increaseCurrentAndNextBalances(recipient, true, amount);

    // When an active balance changes at current timestamp, settle rewards to the current timestamp.
    _settleUserRewardsUpToNow(sender, oldSenderBalance, totalBalance);
    _settleUserRewardsUpToNow(recipient, oldRecipientBalance, totalBalance);
  }

  function _decreaseCurrentAndNextInactiveBalance(
    address staker,
    uint256 amount
  )
    internal
  {
    // Decrease the inactive balance for the next epoch.
    _decreaseCurrentAndNextBalances(address(0), false, amount);
    _decreaseCurrentAndNextBalances(staker, false, amount);

    // Note that we don't settle rewards since active balances are not affected.
  }

  function _settleTotalActiveBalance()
    internal
    returns (uint256)
  {
    return _settleBalance(address(0), true);
  }

  function _settleStakerDebtBalance(
    address staker
  )
    internal
    returns (uint256)
  {
    // Settle the inactive balance to settle any new debt.
    _settleBalance(staker, false);

    // Return the settled debt balance.
    return _STAKER_DEBT_BALANCES_[staker];
  }

  function _settleAndClaimRewards(
    address staker,
    address recipient
  )
    internal
    returns (uint256)
  {
    // Always settle total active balance before settling a staker active balance.
    uint256 totalBalance = _settleTotalActiveBalance();

    // Always settle staker active balance before settling staker rewards.
    uint256 userBalance = _settleBalance(staker, true);

    // Settle rewards balance since we want to claim the full accrued amount.
    _settleUserRewardsUpToNow(staker, userBalance, totalBalance);

    // Claim rewards balance.
    return _claimRewards(staker, recipient);
  }

  function _applyShortfall(
    uint256 shortfallAmount,
    uint256 shortfallIndex
  )
    internal
  {
    // Decrease the total inactive balance.
    _decreaseCurrentAndNextBalances(address(0), false, shortfallAmount);

    _SHORTFALLS_.push(LS1Types.Shortfall({
      epoch: getCurrentEpoch().toUint16(),
      index: shortfallIndex.toUint128()
    }));
  }

  /**
   * @dev Does the same thing as _settleBalance() for a user inactive balance, but limits
   *  the epoch we progress to, in order that we can put an upper bound on the gas expenditure of
   *  the function. See LS1Failsafe.
   */
  function _failsafeSettleUserInactiveBalance(
    address staker,
    uint256 maxEpoch
  )
    internal
  {
    LS1Types.StoredBalance storage balancePtr = _getBalancePtr(staker, false);
    LS1Types.StoredBalance memory balance =
      _failsafeLoadUserInactiveBalanceForUpdate(balancePtr, staker, maxEpoch);
    _storeBalance(balancePtr, balance);
  }

  /**
   * @dev Sets the user inactive balance to zero. See LS1Failsafe.
   *
   *  Since the balance will never be settled, the staker loses any debt balance that they would
   *  have otherwise been entitled to from shortfall losses.
   *
   *  Also note that we don't update the total inactive balance, but this is fine.
   */
  function _failsafeDeleteUserInactiveBalance(
    address staker
  )
    internal
  {
    LS1Types.StoredBalance storage balancePtr = _getBalancePtr(staker, false);
    LS1Types.StoredBalance memory balance =
      LS1Types.StoredBalance({
        currentEpoch: 0,
        currentEpochBalance: 0,
        nextEpochBalance: 0,
        shortfallCounter: 0
      });
    _storeBalance(balancePtr, balance);
  }

  // ============ Private Functions ============

  /**
   * @dev Load a balance for update and then store it.
   */
  function _settleBalance(
    address maybeStaker,
    bool isActiveBalance
  )
    private
    returns (uint256)
  {
    LS1Types.StoredBalance storage balancePtr = _getBalancePtr(maybeStaker, isActiveBalance);
    LS1Types.StoredBalance memory balance =
      _loadBalanceForUpdate(balancePtr, maybeStaker, isActiveBalance);

    uint256 currentBalance = uint256(balance.currentEpochBalance);

    _storeBalance(balancePtr, balance);
    return currentBalance;
  }

  /**
   * @dev Settle a balance while applying an increase.
   */
  function _increaseCurrentAndNextBalances(
    address maybeStaker,
    bool isActiveBalance,
    uint256 amount
  )
    private
    returns (uint256)
  {
    LS1Types.StoredBalance storage balancePtr = _getBalancePtr(maybeStaker, isActiveBalance);
    LS1Types.StoredBalance memory balance =
      _loadBalanceForUpdate(balancePtr, maybeStaker, isActiveBalance);

    uint256 originalCurrentBalance = uint256(balance.currentEpochBalance);
    balance.currentEpochBalance = originalCurrentBalance.add(amount).toUint128();
    balance.nextEpochBalance = uint256(balance.nextEpochBalance).add(amount).toUint128();

    _storeBalance(balancePtr, balance);
    return originalCurrentBalance;
  }

  /**
   * @dev Settle a balance while applying a decrease.
   */
  function _decreaseCurrentAndNextBalances(
    address maybeStaker,
    bool isActiveBalance,
    uint256 amount
  )
    private
    returns (uint256)
  {
    LS1Types.StoredBalance storage balancePtr = _getBalancePtr(maybeStaker, isActiveBalance);
    LS1Types.StoredBalance memory balance =
      _loadBalanceForUpdate(balancePtr, maybeStaker, isActiveBalance);

    uint256 originalCurrentBalance = uint256(balance.currentEpochBalance);
    balance.currentEpochBalance = originalCurrentBalance.sub(amount).toUint128();
    balance.nextEpochBalance = uint256(balance.nextEpochBalance).sub(amount).toUint128();

    _storeBalance(balancePtr, balance);
    return originalCurrentBalance;
  }

  /**
   * @dev Settle a balance while applying an increase.
   */
  function _increaseNextBalance(
    address maybeStaker,
    bool isActiveBalance,
    uint256 amount
  )
    private
  {
    LS1Types.StoredBalance storage balancePtr = _getBalancePtr(maybeStaker, isActiveBalance);
    LS1Types.StoredBalance memory balance =
      _loadBalanceForUpdate(balancePtr, maybeStaker, isActiveBalance);

    balance.nextEpochBalance = uint256(balance.nextEpochBalance).add(amount).toUint128();

    _storeBalance(balancePtr, balance);
  }

  /**
   * @dev Settle a balance while applying a decrease.
   */
  function _decreaseNextBalance(
    address maybeStaker,
    bool isActiveBalance,
    uint256 amount
  )
    private
  {
    LS1Types.StoredBalance storage balancePtr = _getBalancePtr(maybeStaker, isActiveBalance);
    LS1Types.StoredBalance memory balance =
      _loadBalanceForUpdate(balancePtr, maybeStaker, isActiveBalance);

    balance.nextEpochBalance = uint256(balance.nextEpochBalance).sub(amount).toUint128();

    _storeBalance(balancePtr, balance);
  }

  function _getBalancePtr(
    address maybeStaker,
    bool isActiveBalance
  )
    private
    view
    returns (LS1Types.StoredBalance storage)
  {
    // Active.
    if (isActiveBalance) {
      if (maybeStaker != address(0)) {
        return _ACTIVE_BALANCES_[maybeStaker];
      }
      return _TOTAL_ACTIVE_BALANCE_;
    }

    // Inactive.
    if (maybeStaker != address(0)) {
      return _INACTIVE_BALANCES_[maybeStaker];
    }
    return _TOTAL_INACTIVE_BALANCE_;
  }

  /**
   * @dev Load a balance for updating.
   *
   *  IMPORTANT: This function modifies state, and so the balance MUST be stored afterwards.
   *    - For active balances: if a rollover occurs, rewards are settled to the epoch boundary.
   *    - For inactive user balances: if a shortfall occurs, the user's debt balance is increased.
   *
   * @param  balancePtr       A storage pointer to the balance.
   * @param  maybeStaker      The user address, or address(0) to update total balance.
   * @param  isActiveBalance  Whether the balance is an active balance.
   */
  function _loadBalanceForUpdate(
    LS1Types.StoredBalance storage balancePtr,
    address maybeStaker,
    bool isActiveBalance
  )
    private
    returns (LS1Types.StoredBalance memory)
  {
    // Active balance.
    if (isActiveBalance) {
      (
        LS1Types.StoredBalance memory updateBalance,
        uint256 beforeRolloverEpoch,
        uint256 beforeRolloverBalance,
        bool didRolloverOccur
      ) = _loadActiveBalance(balancePtr);
      if (didRolloverOccur) {
        // Handle the effect of the balance rollover on rewards. We must partially settle the index
        // up to the epoch boundary where the change in balance occurred. We pass in the balance
        // from before the boundary.
        if (maybeStaker == address(0)) {
          // If it's the total active balance...
          _settleGlobalIndexUpToEpoch(beforeRolloverBalance, beforeRolloverEpoch);
        } else {
          // If it's a user active balance...
          _settleUserRewardsUpToEpoch(maybeStaker, beforeRolloverBalance, beforeRolloverEpoch);
        }
      }
      return updateBalance;
    }

    // Total inactive balance.
    if (maybeStaker == address(0)) {
      return _loadTotalInactiveBalance(balancePtr);
    }

    // User inactive balance.
    (LS1Types.StoredBalance memory balance, uint256 newStakerDebt) =
      _loadUserInactiveBalance(balancePtr);
    if (newStakerDebt != 0) {
      uint256 newDebtBalance = _STAKER_DEBT_BALANCES_[maybeStaker].add(newStakerDebt);
      _STAKER_DEBT_BALANCES_[maybeStaker] = newDebtBalance;
      emit ReceivedDebt(maybeStaker, newStakerDebt, newDebtBalance);
    }
    return balance;
  }

  function _loadActiveBalance(
    LS1Types.StoredBalance storage balancePtr
  )
    private
    view
    returns (
      LS1Types.StoredBalance memory,
      uint256,
      uint256,
      bool
    )
  {
    LS1Types.StoredBalance memory balance = balancePtr;

    // Return these as they may be needed for rewards settlement.
    uint256 beforeRolloverEpoch = uint256(balance.currentEpoch);
    uint256 beforeRolloverBalance = uint256(balance.currentEpochBalance);
    bool didRolloverOccur = false;

    // Roll the balance forward if needed.
    uint256 currentEpoch = getCurrentEpoch();
    if (currentEpoch > uint256(balance.currentEpoch)) {
      didRolloverOccur = balance.currentEpochBalance != balance.nextEpochBalance;

      balance.currentEpoch = currentEpoch.toUint16();
      balance.currentEpochBalance = balance.nextEpochBalance;
    }

    return (balance, beforeRolloverEpoch, beforeRolloverBalance, didRolloverOccur);
  }

  function _loadTotalInactiveBalance(
    LS1Types.StoredBalance storage balancePtr
  )
    private
    view
    returns (LS1Types.StoredBalance memory)
  {
    LS1Types.StoredBalance memory balance = balancePtr;

    // Roll the balance forward if needed.
    uint256 currentEpoch = getCurrentEpoch();
    if (currentEpoch > uint256(balance.currentEpoch)) {
      balance.currentEpoch = currentEpoch.toUint16();
      balance.currentEpochBalance = balance.nextEpochBalance;
    }

    return balance;
  }

  function _loadUserInactiveBalance(
    LS1Types.StoredBalance storage balancePtr
  )
    private
    view
    returns (LS1Types.StoredBalance memory, uint256)
  {
    LS1Types.StoredBalance memory balance = balancePtr;
    uint256 currentEpoch = getCurrentEpoch();

    // If there is no non-zero balance, sync the epoch number and shortfall counter and exit.
    // Note: Next inactive balance is always >= current, so we only need to check next.
    if (balance.nextEpochBalance == 0) {
      balance.currentEpoch = currentEpoch.toUint16();
      balance.shortfallCounter = _SHORTFALLS_.length.toUint16();
      return (balance, 0);
    }

    // Apply any pending shortfalls that don't affect the “next epoch” balance.
    uint256 newStakerDebt;
    (balance, newStakerDebt) = _applyShortfallsToBalance(balance);

    // Roll the balance forward if needed.
    if (currentEpoch > uint256(balance.currentEpoch)) {
      balance.currentEpoch = currentEpoch.toUint16();
      balance.currentEpochBalance = balance.nextEpochBalance;

      // Check for more shortfalls affecting the “next epoch” and beyond.
      uint256 moreNewStakerDebt;
      (balance, moreNewStakerDebt) = _applyShortfallsToBalance(balance);
      newStakerDebt = newStakerDebt.add(moreNewStakerDebt);
    }

    return (balance, newStakerDebt);
  }

  function _applyShortfallsToBalance(
    LS1Types.StoredBalance memory balance
  )
    private
    view
    returns (LS1Types.StoredBalance memory, uint256)
  {
    // Get the cached and global shortfall counters.
    uint256 shortfallCounter = uint256(balance.shortfallCounter);
    uint256 globalShortfallCounter = _SHORTFALLS_.length;

    // If the counters are in sync, then there is nothing to do.
    if (shortfallCounter == globalShortfallCounter) {
      return (balance, 0);
    }

    // Get the balance params.
    uint16 cachedEpoch = balance.currentEpoch;
    uint256 oldCurrentBalance = uint256(balance.currentEpochBalance);

    // Calculate the new balance after applying shortfalls.
    //
    // Note: In theory, this while-loop may render an account's funds inaccessible if there are
    // too many shortfalls, and too much gas is required to apply them all. This is very unlikely
    // to occur in practice, but we provide _failsafeLoadUserInactiveBalance() just in case to
    // ensure recovery is possible.
    uint256 newCurrentBalance = oldCurrentBalance;
    while (shortfallCounter < globalShortfallCounter) {
      LS1Types.Shortfall memory shortfall = _SHORTFALLS_[shortfallCounter];

      // Stop applying shortfalls if they are in the future relative to the balance current epoch.
      if (shortfall.epoch > cachedEpoch) {
        break;
      }

      // Update the current balance to reflect the shortfall.
      uint256 shortfallIndex = uint256(shortfall.index);
      newCurrentBalance = newCurrentBalance.mul(shortfallIndex).div(SHORTFALL_INDEX_BASE);

      // Increment the staker's shortfall counter.
      shortfallCounter = shortfallCounter.add(1);
    }

    // Calculate the loss.
    // If the loaded balance is stored, this amount must be added to the staker's debt balance.
    uint256 newStakerDebt = oldCurrentBalance.sub(newCurrentBalance);

    // Update the balance.
    balance.currentEpochBalance = newCurrentBalance.toUint128();
    balance.nextEpochBalance = uint256(balance.nextEpochBalance).sub(newStakerDebt).toUint128();
    balance.shortfallCounter = shortfallCounter.toUint16();
    return (balance, newStakerDebt);
  }

  /**
   * @dev Store a balance.
   */
  function _storeBalance(
    LS1Types.StoredBalance storage balancePtr,
    LS1Types.StoredBalance memory balance
  )
    private
  {
    // Note: This should use a single `sstore` when compiler optimizations are enabled.
    balancePtr.currentEpoch = balance.currentEpoch;
    balancePtr.currentEpochBalance = balance.currentEpochBalance;
    balancePtr.nextEpochBalance = balance.nextEpochBalance;
    balancePtr.shortfallCounter = balance.shortfallCounter;
  }

  /**
   * @dev Does the same thing as _loadBalanceForUpdate() for a user inactive balance, but limits
   *  the epoch we progress to, in order that we can put an upper bound on the gas expenditure of
   *  the function. See LS1Failsafe.
   */
  function _failsafeLoadUserInactiveBalanceForUpdate(
    LS1Types.StoredBalance storage balancePtr,
    address staker,
    uint256 maxEpoch
  )
    private
    returns (LS1Types.StoredBalance memory)
  {
    LS1Types.StoredBalance memory balance = balancePtr;

    // Validate maxEpoch.
    uint256 currentEpoch = getCurrentEpoch();
    uint256 cachedEpoch = uint256(balance.currentEpoch);
    require(
      maxEpoch >= cachedEpoch && maxEpoch <= currentEpoch,
      'maxEpoch'
    );

    // Apply any pending shortfalls that don't affect the “next epoch” balance.
    uint256 newStakerDebt;
    (balance, newStakerDebt) = _applyShortfallsToBalance(balance);

    // Roll the balance forward if needed.
    if (maxEpoch > cachedEpoch) {
      balance.currentEpoch = maxEpoch.toUint16(); // Use maxEpoch instead of currentEpoch.
      balance.currentEpochBalance = balance.nextEpochBalance;

      // Check for more shortfalls affecting the “next epoch” and beyond.
      uint256 moreNewStakerDebt;
      (balance, moreNewStakerDebt) = _applyShortfallsToBalance(balance);
      newStakerDebt = newStakerDebt.add(moreNewStakerDebt);
    }

    // Apply debt if needed.
    if (newStakerDebt != 0) {
      uint256 newDebtBalance = _STAKER_DEBT_BALANCES_[staker].add(newStakerDebt);
      _STAKER_DEBT_BALANCES_[staker] = newDebtBalance;
      emit ReceivedDebt(staker, newStakerDebt, newDebtBalance);
    }
    return balance;
  }
}