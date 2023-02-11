// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;
pragma abicoder v2;

import { SafeMathUpgradeable } from '@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol';
import { LS1Staking } from './LS1Staking.sol';

/**
 * @title LS1Operators
 * @author MarginX
 *
 * @dev Actions which may be called by authorized operators, nominated by the contract owner.
 *
 *  There are three types of operators. These should be smart contracts, which can be used to
 *  provide additional functionality to users:
 *
 *  STAKE_OPERATOR_ROLE:
 *
 *    This operator is allowed to request withdrawals and withdraw funds on behalf of stakers. This
 *    role could be used by a smart contract to provide a staking interface with additional
 *    features, for example, optional lock-up periods that pay out additional rewards (from a
 *    separate rewards pool).
 *
 *  CLAIM_OPERATOR_ROLE:
 *
 *    This operator is allowed to claim rewards on behalf of stakers. This role could be used by a
 *    smart contract to provide an interface for claiming rewards from multiple incentive programs
 *    at once.
 *
 *  DEBT_OPERATOR_ROLE:
 *
 *    This operator is allowed to decrease staker and borrower debt balances. Typically, each change
 *    to a staker debt balance should be offset by a corresponding change in a borrower debt
 *    balance, but this is not strictly required. This role could used by a smart contract to
 *    tokenize debt balances or to provide a pro-rata distribution to debt holders, for example.
 */
abstract contract LS1Operators is
  LS1Staking
{
  using SafeMathUpgradeable for uint256;

  // ============ Events ============

  event OperatorStakedFor(
    address indexed staker,
    uint256 amount,
    address operator
  );

  event OperatorWithdrawalRequestedFor(
    address indexed staker,
    uint256 amount,
    address operator
  );

  event OperatorWithdrewStakeFor(
    address indexed staker,
    address recipient,
    uint256 amount,
    address operator
  );

  event OperatorClaimedRewardsFor(
    address indexed staker,
    address recipient,
    uint256 claimedRewards,
    address operator
  );

  event OperatorDecreasedStakerDebt(
    address indexed staker,
    uint256 amount,
    uint256 newDebtBalance,
    address operator
  );

  event OperatorDecreasedBorrowerDebt(
    address indexed borrower,
    uint256 amount,
    uint256 newDebtBalance,
    address operator
  );

  // ============ External Functions ============

  /**
   * @notice Request a withdrawal on behalf of a staker.
   *
   *  Reverts if we are currently in the blackout window.
   *
   * @param  staker  The staker whose stake to request a withdrawal for.
   * @param  amount  The amount to move from the active to the inactive balance.
   */
  function requestWithdrawalFor(
    address staker,
    uint256 amount
  )
    external
    onlyRole(STAKE_OPERATOR_ROLE)
    nonReentrant
  {
    _requestWithdrawal(staker, amount);
    emit OperatorWithdrawalRequestedFor(staker, amount, msg.sender);
  }

  /**
   * @notice Withdraw a staker's stake, and send to the specified recipient.
   *
   * @param  staker     The staker whose stake to withdraw.
   * @param  recipient  The address that should receive the funds.
   * @param  amount     The amount to withdraw from the staker's inactive balance.
   */
  function withdrawStakeFor(
    address staker,
    address recipient,
    uint256 amount
  )
    external
    onlyRole(STAKE_OPERATOR_ROLE)
    nonReentrant
  {
    _withdrawStake(staker, recipient, amount);
    emit OperatorWithdrewStakeFor(staker, recipient, amount, msg.sender);
  }

  /**
   * @notice Claim rewards on behalf of a staker, and send them to the specified recipient.
   *
   * @param  staker     The staker whose rewards to claim.
   * @param  recipient  The address that should receive the funds.
   *
   * @return The number of rewards tokens claimed.
   */
  function claimRewardsFor(
    address staker,
    address recipient
  )
    external
    onlyRole(CLAIM_OPERATOR_ROLE)
    nonReentrant
    returns (uint256)
  {
    uint256 rewards = _settleAndClaimRewards(staker, recipient); // Emits an event internally.
    emit OperatorClaimedRewardsFor(staker, recipient, rewards, msg.sender);
    return rewards;
  }

  /**
   * @notice Decreased the balance recording debt owed to a staker.
   *
   * @param  staker  The staker whose balance to decrease.
   * @param  amount  The amount to decrease the balance by.
   *
   * @return The new debt balance.
   */
  function decreaseStakerDebt(
    address staker,
    uint256 amount
  )
    external
    onlyRole(DEBT_OPERATOR_ROLE)
    nonReentrant
    returns (uint256)
  {
    uint256 oldDebtBalance = _settleStakerDebtBalance(staker);
    uint256 newDebtBalance = oldDebtBalance.sub(amount);
    _STAKER_DEBT_BALANCES_[staker] = newDebtBalance;
    emit OperatorDecreasedStakerDebt(staker, amount, newDebtBalance, msg.sender);
    return newDebtBalance;
  }

  /**
   * @notice Decreased the balance recording debt owed by a borrower.
   *
   * @param  borrower  The borrower whose balance to decrease.
   * @param  amount    The amount to decrease the balance by.
   *
   * @return The new debt balance.
   */
  function decreaseBorrowerDebt(
    address borrower,
    uint256 amount
  )
    external
    onlyRole(DEBT_OPERATOR_ROLE)
    nonReentrant
    returns (uint256)
  {
    uint256 newDebtBalance = _BORROWER_DEBT_BALANCES_[borrower].sub(amount);
    _BORROWER_DEBT_BALANCES_[borrower] = newDebtBalance;
    _TOTAL_BORROWER_DEBT_BALANCE_ = _TOTAL_BORROWER_DEBT_BALANCE_.sub(amount);
    emit OperatorDecreasedBorrowerDebt(borrower, amount, newDebtBalance, msg.sender);
    return newDebtBalance;
  }
}