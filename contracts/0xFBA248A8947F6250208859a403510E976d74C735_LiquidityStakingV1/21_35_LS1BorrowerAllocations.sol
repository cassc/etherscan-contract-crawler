// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;
pragma abicoder v2;

import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { MathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import { LS1Types } from "../lib/LS1Types.sol";
import { SafeCast } from "../lib/SafeCast.sol";
import { LS1StakedBalances } from "./LS1StakedBalances.sol";

/**
 * @title LS1BorrowerAllocations
 * @author MarginX
 *
 * @dev Gives a set of addresses permission to withdraw staked funds.
 *
 *  The amount that can be withdrawn depends on a borrower's allocation percentage and the total
 *  available funds. Both the allocated percentage and total available funds can change, at
 *  predefined times specified by LS1EpochSchedule.
 *
 *  If a borrower's borrowed balance is greater than their allocation at the start of the next epoch
 *  then they are expected and trusted to return the difference before the start of that epoch.
 */
abstract contract LS1BorrowerAllocations is
  LS1StakedBalances
{
  using SafeCast for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using SafeMathUpgradeable for uint256;

  // ============ Constants ============

  /// @notice The total units to be allocated.
  uint256 public constant TOTAL_ALLOCATION = 1e4;

  // ============ Events ============

  event ScheduledBorrowerAllocationChange(
    address indexed borrower,
    uint256 oldAllocation,
    uint256 newAllocation,
    uint256 epochNumber
  );

  event BorrowingRestrictionChanged(
    address indexed borrower,
    bool isBorrowingRestricted
  );

  // ============ Initializer ============

  function __LS1BorrowerAllocations_init()
    internal
  {
    _BORROWER_ALLOCATIONS_[address(0)] = LS1Types.StoredAllocation({
      currentEpoch: 0,
      currentEpochAllocation: TOTAL_ALLOCATION.toUint128(),
      nextEpochAllocation: TOTAL_ALLOCATION.toUint128()
    });
  }

  // ============ Public Functions ============

  /**
   * @notice Get the borrower allocation for the current epoch.
   *
   * @param  borrower  The borrower to get the allocation for.
   *
   * @return The borrower's current allocation in hundreds of a percent.
   */
  function getAllocationFractionCurrentEpoch(
    address borrower
  )
    public
    view
    returns (uint256)
  {
    return uint256(_loadBorrowerAllocation(borrower).currentEpochAllocation);
  }

  /**
   * @notice Get the borrower allocation for the next epoch.
   *
   * @param  borrower  The borrower to get the allocation for.
   *
   * @return The borrower's next allocation in hundreds of a percent.
   */
  function getAllocationFractionNextEpoch(
    address borrower
  )
    public
    view
    returns (uint256)
  {
    return uint256(_loadBorrowerAllocation(borrower).nextEpochAllocation);
  }

  /**
   * @notice Get the allocated borrowable token balance of a borrower for the current epoch.
   *
   *  This is the amount which a borrower can be penalized for exceeding.
   *
   * @param  borrower  The borrower to get the allocation for.
   *
   * @return The token amount allocated to the borrower for the current epoch.
   */
  function getAllocatedBalanceCurrentEpoch(
    address borrower
  )
    public
    view
    returns (uint256)
  {
    uint256 allocation = getAllocationFractionCurrentEpoch(borrower);
    uint256 availableTokens = getTotalActiveBalanceCurrentEpoch();
    return availableTokens.mul(allocation).div(TOTAL_ALLOCATION);
  }

  /**
   * @notice Preview the allocated balance of a borrower for the next epoch.
   *
   * @param  borrower  The borrower to get the allocation for.
   *
   * @return The anticipated token amount allocated to the borrower for the next epoch.
   */
  function getAllocatedBalanceNextEpoch(
    address borrower
  )
    public
    view
    returns (uint256)
  {
    uint256 allocation = getAllocationFractionNextEpoch(borrower);
    uint256 availableTokens = getTotalActiveBalanceNextEpoch();
    return availableTokens.mul(allocation).div(TOTAL_ALLOCATION);
  }

  // ============ Internal Functions ============

  /**
   * @dev Change the allocations of certain borrowers.
   */
  function _setBorrowerAllocations(
    address[] calldata borrowers,
    uint256[] calldata newAllocations
  )
    internal
  {
    // These must net out so that the total allocation is unchanged.
    uint256 oldAllocationSum = 0;
    uint256 newAllocationSum = 0;

    for (uint256 i = 0; i < borrowers.length; i++) {
      address borrower = borrowers[i];
      uint256 newAllocation = newAllocations[i];

      // Get the old allocation.
      LS1Types.StoredAllocation memory allocationStruct = _loadBorrowerAllocation(borrower);
      uint256 oldAllocation = uint256(allocationStruct.currentEpochAllocation);

      // Update the borrower's next allocation.
      allocationStruct.nextEpochAllocation = newAllocation.toUint128();

      // If epoch zero hasn't started, update current allocation as well.
      uint256 epochNumber = 0;
      if (hasEpochZeroStarted()) {
        epochNumber = uint256(allocationStruct.currentEpoch).add(1);
      } else {
        allocationStruct.currentEpochAllocation = newAllocation.toUint128();
      }

      // Commit the new allocation.
      _BORROWER_ALLOCATIONS_[borrower] = allocationStruct;
      emit ScheduledBorrowerAllocationChange(borrower, oldAllocation, newAllocation, epochNumber);

      // Record totals.
      oldAllocationSum = oldAllocationSum.add(oldAllocation);
      newAllocationSum = newAllocationSum.add(newAllocation);
    }

    // Require the total allocated units to be unchanged.
    require(
      oldAllocationSum == newAllocationSum,
      'Invalid'
    );
  }

 /**
   * @dev Restrict a borrower from further borrowing.
   */
  function _setBorrowingRestriction(
    address borrower,
    bool isBorrowingRestricted
  )
    internal
  {
    bool oldIsBorrowingRestricted = _BORROWER_RESTRICTIONS_[borrower];
    if (oldIsBorrowingRestricted != isBorrowingRestricted) {
      _BORROWER_RESTRICTIONS_[borrower] = isBorrowingRestricted;
      emit BorrowingRestrictionChanged(borrower, isBorrowingRestricted);
    }
  }

  /**
   * @dev Get the allocated balance that the borrower can make use of for new borrowing.
   *
   * @return The amount that the borrower can borrow up to.
   */
  function _getAllocatedBalanceForNewBorrowing(
    address borrower
  )
    internal
    view
    returns (uint256)
  {
    // Use the smaller of the current and next allocation fractions, since if a borrower's
    // allocation was just decreased, we should take that into account in limiting new borrows.
    uint256 currentAllocation = getAllocationFractionCurrentEpoch(borrower);
    uint256 nextAllocation = getAllocationFractionNextEpoch(borrower);
    uint256 allocation = MathUpgradeable.min(currentAllocation, nextAllocation);

    // If we are in the blackout window, use the next active balance. Otherwise, use current.
    // Note that the next active balance is never greater than the current active balance.
    uint256 availableTokens;
    if (inBlackoutWindow()) {
      availableTokens = getTotalActiveBalanceNextEpoch();
    } else {
      availableTokens = getTotalActiveBalanceCurrentEpoch();
    }
    return availableTokens.mul(allocation).div(TOTAL_ALLOCATION);
  }

  // ============ Private Functions ============

  function _loadBorrowerAllocation(
    address borrower
  )
    private
    view
    returns (LS1Types.StoredAllocation memory)
  {
    LS1Types.StoredAllocation memory allocation = _BORROWER_ALLOCATIONS_[borrower];

    // Ignore rollover logic before epoch zero.
    if (hasEpochZeroStarted()) {
      uint256 currentEpoch = getCurrentEpoch();
      if (currentEpoch > uint256(allocation.currentEpoch)) {
        // Roll the allocation forward.
        allocation.currentEpoch = currentEpoch.toUint16();
        allocation.currentEpochAllocation = allocation.nextEpochAllocation;
      }
    }

    return allocation;
  }
}