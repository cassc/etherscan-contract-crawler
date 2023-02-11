// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;
pragma abicoder v2;

import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { MathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import { LS1Types } from '../lib/LS1Types.sol';
import { LS1ERC20 } from './LS1ERC20.sol';
import { LS1StakedBalances } from './LS1StakedBalances.sol';

/**
 * @title LS1Staking
 * @author MarginX
 *
 * @dev External functions for stakers. See LS1StakedBalances for details on staker accounting.
 */
abstract contract LS1Staking is
  LS1StakedBalances,
  LS1ERC20
{
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using SafeMathUpgradeable for uint256;

  // ============ Events ============

  event Staked(
    address indexed staker,
    address spender,
    uint256 amount
  );

  event WithdrawalRequested(
    address indexed staker,
    uint256 amount
  );

  event WithdrewStake(
    address indexed staker,
    address recipient,
    uint256 amount
  );

  event WithdrewDebt(
    address indexed staker,
    address recipient,
    uint256 amount,
    uint256 newDebtBalance
  );

  // ============ Constants ============

  IERC20Upgradeable public STAKED_TOKEN;

  // ============ External Functions ============

  /**
   * @notice Deposit and stake funds. These funds are active and start earning rewards immediately.
   *
   * @param  amount  The amount to stake.
   */
  function stake(
    uint256 amount
  )
    external
    nonReentrant
  {
    _stake(msg.sender, amount);
  }

  /**
   * @notice Request to withdraw funds. Starting in the next epoch, the funds will be “inactive”
   *  and available for withdrawal. Inactive funds do not earn rewards.
   *
   *  Reverts if we are currently in the blackout window.
   *
   * @param  amount  The amount to move from the active to the inactive balance.
   */
  function requestWithdrawal(
    uint256 amount
  )
    external
    nonReentrant
  {
    _requestWithdrawal(msg.sender, amount);
  }

  /**
   * @notice Withdraw the sender's inactive funds, and send to the specified recipient.
   *
   * @param  recipient  The address that should receive the funds.
   * @param  amount     The amount to withdraw from the sender's inactive balance.
   */
  function withdrawStake(
    address recipient,
    uint256 amount
  )
    external
    nonReentrant
  {
    _withdrawStake(msg.sender, recipient, amount);
  }

  /**
   * @notice Withdraw the max available inactive funds, and send to the specified recipient.
   *
   *  This is less gas-efficient than querying the max via eth_call and calling withdrawStake().
   *
   * @param  recipient  The address that should receive the funds.
   *
   * @return The withdrawn amount.
   */
  function withdrawMaxStake(
    address recipient
  )
    external
    nonReentrant
    returns (uint256)
  {
    uint256 amount = getStakeAvailableToWithdraw(msg.sender);
    _withdrawStake(msg.sender, recipient, amount);
    return amount;
  }

  /**
   * @notice Withdraw a debt amount owed to the sender, and send to the specified recipient.
   *
   * @param  recipient  The address that should receive the funds.
   * @param  amount     The token amount to withdraw from the sender's debt balance.
   */
  function withdrawDebt(
    address recipient,
    uint256 amount
  )
    external
    nonReentrant
  {
    _withdrawDebt(msg.sender, recipient, amount);
  }

  /**
   * @notice Withdraw the max available debt amount.
   *
   *  This is less gas-efficient than querying the max via eth_call and calling withdrawDebt().
   *
   * @param  recipient  The address that should receive the funds.
   *
   * @return The withdrawn amount.
   */
  function withdrawMaxDebt(
    address recipient
  )
    external
    nonReentrant
    returns (uint256)
  {
    uint256 amount = getDebtAvailableToWithdraw(msg.sender);
    _withdrawDebt(msg.sender, recipient, amount);
    return amount;
  }

  /**
   * @notice Settle and claim all rewards, and send them to the specified recipient.
   *
   *  Call this function with eth_call to query the claimable rewards balance.
   *
   * @param  recipient  The address that should receive the funds.
   *
   * @return The number of rewards tokens claimed.
   */
  function claimRewards(
    address recipient
  )
    external
    nonReentrant
    returns (uint256)
  {
    return _settleAndClaimRewards(msg.sender, recipient); // Emits an event internally.
  }

  // ============ Public Functions ============

  /**
   * @notice Get the amount of stake available to withdraw taking into account the contract balance.
   *
   * @param  staker  The address whose balance to check.
   *
   * @return The staker's stake amount that is inactive and available to withdraw.
   */
  function getStakeAvailableToWithdraw(
    address staker
  )
    public
    view
    returns (uint256)
  {
    // Note that the next epoch inactive balance is always at least that of the current epoch.
    uint256 stakerBalance = getInactiveBalanceCurrentEpoch(staker);
    uint256 totalStakeAvailable = getContractBalanceAvailableToWithdraw();
    return MathUpgradeable.min(stakerBalance, totalStakeAvailable);
  }

  /**
   * @notice Get the funds currently available in the contract for staker withdrawals.
   *
   * @return The amount of non-debt funds in the contract.
   */
  function getContractBalanceAvailableToWithdraw()
    public
    view
    returns (uint256)
  {
    uint256 contractBalance = STAKED_TOKEN.balanceOf(address(this));
    uint256 availableDebtBalance = _TOTAL_DEBT_AVAILABLE_TO_WITHDRAW_;
    return contractBalance.sub(availableDebtBalance); // Should never underflow.
  }

  /**
   * @notice Get the amount of debt available to withdraw.
   *
   * @param  staker  The address whose balance to check.
   *
   * @return The debt amount that can be withdrawn.
   */
  function getDebtAvailableToWithdraw(
    address staker
  )
    public
    view
    returns (uint256)
  {
    // Note that `totalDebtAvailable` should never be less than the contract token balance.
    uint256 stakerDebtBalance = getStakerDebtBalance(staker);
    uint256 totalDebtAvailable = _TOTAL_DEBT_AVAILABLE_TO_WITHDRAW_;
    return MathUpgradeable.min(stakerDebtBalance, totalDebtAvailable);
  }


  // ============ Internal Functions ============

  function _stake(
    address staker,
    uint256 amount
  )
    internal
  {
    require(
      getTotalActiveBalanceCurrentEpoch() + amount <= _MAX_POOL_SIZE_,
      '> Max Pool Size'
    );
    // Increase current and next active balance.
    _increaseCurrentAndNextActiveBalance(staker, amount);

    // Transfer token from the sender.
    STAKED_TOKEN.safeTransferFrom(msg.sender, address(this), amount);

    emit Staked(staker, msg.sender, amount);
    emit Transfer(address(0), msg.sender, amount);
  }

  function _requestWithdrawal(
    address staker,
    uint256 amount
  )
    internal
  {
    require(
      !inBlackoutWindow(),
      'Requests restricted in the B.O window'
    );

    // Get the staker's requestable amount and revert if there is not enough to request withdrawal.
    uint256 requestableBalance = getActiveBalanceNextEpoch(staker);
    require(
      amount <= requestableBalance,
      'Request > next active balance'
    );

    // Move amount from active to inactive in the next epoch.
    _moveNextBalanceActiveToInactive(staker, amount);

    emit WithdrawalRequested(staker, amount);
  }

  function _withdrawStake(
    address staker,
    address recipient,
    uint256 amount
  )
    internal
  {
    // Get contract available amount and revert if there is not enough to withdraw.
    uint256 totalStakeAvailable = getContractBalanceAvailableToWithdraw();
    require(
      amount <= totalStakeAvailable,
      'Withdraw > amount available in the contract'
    );

    // Get staker withdrawable balance and revert if there is not enough to withdraw.
    uint256 withdrawableBalance = getInactiveBalanceCurrentEpoch(staker);
    require(
      amount <= withdrawableBalance,
      'Withdraw > inactive balance'
    );

    // Decrease the staker's current and next inactive balance. Reverts if balance is insufficient.
    _decreaseCurrentAndNextInactiveBalance(staker, amount);

    // Transfer token to the recipient.
    STAKED_TOKEN.safeTransfer(recipient, amount);

    emit Transfer(msg.sender, address(0), amount);
    emit WithdrewStake(staker, recipient, amount);
  }

  // ============ Private Functions ============

  function _withdrawDebt(
    address staker,
    address recipient,
    uint256 amount
  )
    private
  {
    // Get old amounts and revert if there is not enough to withdraw.
    uint256 oldDebtBalance = _settleStakerDebtBalance(staker);
    require(
      amount <= oldDebtBalance,
      'Withdraw debt > debt owed'
    );
    uint256 oldDebtAvailable = _TOTAL_DEBT_AVAILABLE_TO_WITHDRAW_;
    require(
      amount <= oldDebtAvailable,
      'Withdraw debt > amount available'
    );

    // Caculate updated amounts and update storage.
    uint256 newDebtBalance = oldDebtBalance.sub(amount);
    uint256 newDebtAvailable = oldDebtAvailable.sub(amount);
    _STAKER_DEBT_BALANCES_[staker] = newDebtBalance;
    _TOTAL_DEBT_AVAILABLE_TO_WITHDRAW_ = newDebtAvailable;

    // Transfer token to the recipient.
    STAKED_TOKEN.safeTransfer(recipient, amount);

    emit WithdrewDebt(staker, recipient, amount, newDebtBalance);
  }
}