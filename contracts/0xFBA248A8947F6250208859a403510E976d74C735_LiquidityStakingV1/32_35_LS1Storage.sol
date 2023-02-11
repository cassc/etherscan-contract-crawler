// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;
pragma abicoder v2;

import { AccessControlUpgradeable } from '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { LS1Types } from '../lib/LS1Types.sol';

/**
 * @title LS1Storage
 * @author MarginX
 *
 * @dev Storage contract. Contains or inherits from all contract with storage.
 */
abstract contract LS1Storage is
  AccessControlUpgradeable,
  ReentrancyGuardUpgradeable
{
  // ============ Epoch setting ============

  /// @dev The parameters specifying the function from timestamp to epoch number.
  LS1Types.EpochParameters internal _EPOCH_PARAMETERS_;

  /// @dev The period of time at the end of each epoch in which withdrawals cannot be requested.
  ///  We also restrict other changes which could affect borrowers' repayment plans, such as
  ///  modifications to the epoch schedule, or to borrower allocations.
  uint256 internal _BLACKOUT_WINDOW_;

  /// @dev The max pool size allowed.
  uint256 internal _MAX_POOL_SIZE_;

  // ============ Staked Token ERC20 ============

  mapping(address => mapping(address => uint256)) internal _ALLOWANCES_;

  // ============ Rewards Accounting ============

  /// @dev The emission rate of rewards.
  uint256 internal _REWARDS_PER_SECOND_;

  /// @dev The cumulative rewards earned per staked token. (Shared storage slot.)
  uint224 internal _GLOBAL_INDEX_;

  /// @dev The timestamp at which the global index was last updated. (Shared storage slot.)
  uint32 internal _GLOBAL_INDEX_TIMESTAMP_;

  /// @dev The value of the global index when the user's staked balance was last updated.
  mapping(address => uint256) internal _USER_INDEXES_;

  /// @dev The user's accrued, unclaimed rewards (as of the last update to the user index).
  mapping(address => uint256) internal _USER_REWARDS_BALANCES_;

  /// @dev The value of the global index at the end of a given epoch.
  mapping(uint256 => uint256) internal _EPOCH_INDEXES_;

  // ============ Staker Accounting ============

  /// @dev The active balance by staker.
  mapping(address => LS1Types.StoredBalance) internal _ACTIVE_BALANCES_;

  /// @dev The total active balance of stakers.
  LS1Types.StoredBalance internal _TOTAL_ACTIVE_BALANCE_;

  /// @dev The inactive balance by staker.
  mapping(address => LS1Types.StoredBalance) internal _INACTIVE_BALANCES_;

  /// @dev The total inactive balance of stakers. Note: The shortfallCounter field is unused.
  LS1Types.StoredBalance internal _TOTAL_INACTIVE_BALANCE_;

  /// @dev Information about shortfalls that have occurred.
  LS1Types.Shortfall[] internal _SHORTFALLS_;

  // ============ Borrower Accounting ============

  /// @dev The units allocated to each borrower.
  /// @dev Values are represented relative to total allocation, i.e. as hundredeths of a percent.
  ///  Also, the total of the values contained in the mapping must always equal the total
  ///  allocation (i.e. must sum to 10,000).
  mapping(address => LS1Types.StoredAllocation) internal _BORROWER_ALLOCATIONS_;

  /// @dev The token balance currently borrowed by the borrower.
  mapping(address => uint256) internal _BORROWED_BALANCES_;

  /// @dev The total token balance currently borrowed by borrowers.
  uint256 internal _TOTAL_BORROWED_BALANCE_;

  /// @dev Indicates whether a borrower is restricted from new borrowing.
  mapping(address => bool) internal _BORROWER_RESTRICTIONS_;

  // ============ Debt Accounting ============

  /// @dev The debt balance owed to each staker.
  mapping(address => uint256) internal _STAKER_DEBT_BALANCES_;

  /// @dev The debt balance by borrower.
  mapping(address => uint256) internal _BORROWER_DEBT_BALANCES_;

  /// @dev The total debt balance of borrowers.
  uint256 internal _TOTAL_BORROWER_DEBT_BALANCE_;

  /// @dev The total debt amount repaid and not yet withdrawn.
  uint256 internal _TOTAL_DEBT_AVAILABLE_TO_WITHDRAW_;
}