// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;
import {ISchedule} from "./ISchedule.sol";
import {ILoan} from "./ILoan.sol";
import {ICreditLine} from "./ICreditLine.sol";

interface ITranchedPool is ILoan {
  struct TrancheInfo {
    uint256 id;
    uint256 principalDeposited;
    uint256 principalSharePrice;
    uint256 interestSharePrice;
    uint256 lockedUntil;
  }
  struct PoolSlice {
    TrancheInfo seniorTranche;
    TrancheInfo juniorTranche;
    uint256 totalInterestAccrued;
    uint256 principalDeployed;
  }
  enum Tranches {
    Reserved,
    Senior,
    Junior
  }

  /// @notice Initialize the pool. Can only be called once, and should be called in the same transaction as
  ///   contract creation to avoid initialization front-running
  /// @param _config address of GoldfinchConfig
  /// @param _borrower address of borrower, a non-transferrable role for performing privileged actions like
  ///   drawdown
  /// @param _juniorFeePercent percent (whole number) of senior interest that gets re-allocated to the junior tranche.
  ///   valid range is [0, 100]
  /// @param _limit the max USDC amount that can be drawn down across all pool slices
  /// @param _interestApr interest rate for the loan
  /// @param _lateFeeApr late fee interest rate for the loan, which kicks in `LatenessGracePeriodInDays` days after a
  ///   payment becomes late
  /// @param _fundableAt earliest time at which the first slice can be funded
  function initialize(
    address _config,
    address _borrower,
    uint256 _juniorFeePercent,
    uint256 _limit,
    uint256 _interestApr,
    ISchedule _schedule,
    uint256 _lateFeeApr,
    uint256 _fundableAt,
    uint256[] calldata _allowedUIDTypes
  ) external;

  /// @notice Pay down the credit line, separating the principal and interest payments. You must pay back all interest
  ///   before paying back principal. Excess payments are refunded to the caller
  /// @param principalPayment USDC amount to pay down principal
  /// @param interestPayment USDC amount to pay down interest
  /// @return PaymentAllocation info on how the payment was allocated
  /// @dev {this} must be approved by msg.sender to transfer {principalPayment} + {interestPayment} of USDC
  function pay(
    uint256 principalPayment,
    uint256 interestPayment
  ) external returns (PaymentAllocation memory);

  /// @notice TrancheInfo for tranche with id `trancheId`. The senior tranche of slice i has id 2*(i-1)+1. The
  ///   junior tranche of slice i has id 2*i. Slice indices start at 1.
  /// @param trancheId id of tranche. Valid ids are in the range [1, 2*numSlices]
  function getTranche(uint256 trancheId) external view returns (ITranchedPool.TrancheInfo memory);

  /// @notice Get a slice by index
  /// @param index of slice. Valid indices are on the interval [0, numSlices - 1]
  function poolSlices(uint256 index) external view returns (ITranchedPool.PoolSlice memory);

  /// @notice Lock the junior capital in the junior tranche of the current slice. The capital is locked for
  ///   `DrawdownPeriodInSeconds` seconds and gives the senior pool time to decide how much to invest (ensure
  ///   leverage ratio cannot change for the period). During this period the borrower has the option to lock
  ///   the senior capital by calling `lockPool()`. Backers may withdraw their junior capital if the the senior
  ///   tranche has not been locked and the drawdown period has ended. Only the borrower can call this function.
  function lockJuniorCapital() external;

  /// @notice Lock the senior capital in the senior tranche of the current slice and reset the lock period of
  ///   the junior capital to match the senior capital lock period. During this period the borrower has the
  ///   option to draw down the pool. Beyond the drawdown period any unused capital is available to withdraw by
  ///   all depositors.
  function lockPool() external;

  /// @notice Initialize the next slice for the pool. Enables backers and the senior pool to provide additional
  ///   capital to the borrower.
  /// @param _fundableAt time at which the new slice (now the current slice) becomes fundable
  function initializeNextSlice(uint256 _fundableAt) external;

  /// @notice Query the total capital supplied to the pool's junior tranches
  function totalJuniorDeposits() external view returns (uint256);

  function assess() external;

  /// @notice Get the current number of slices for this pool
  /// @return numSlices total current slice count
  function numSlices() external view returns (uint256);

  // Note: This has to exactly match the event in the TranchingLogic library for events to be emitted
  // correctly
  event SharePriceUpdated(
    address indexed pool,
    uint256 indexed tranche,
    uint256 principalSharePrice,
    int256 principalDelta,
    uint256 interestSharePrice,
    int256 interestDelta
  );
  event CreditLineMigrated(ICreditLine indexed oldCreditLine, ICreditLine indexed newCreditLine);
  event TrancheLocked(address indexed pool, uint256 trancheId, uint256 lockedUntil);
  event SliceCreated(address indexed pool, uint256 sliceId);
}