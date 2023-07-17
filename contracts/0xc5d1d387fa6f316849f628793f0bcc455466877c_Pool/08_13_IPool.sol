// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

/// @title Prime IPool contract interface
interface IPool {
  /// @notice Pool member data struct
  struct Member {
    bool isCreated; // True if the member is created
    bool isWhitelisted; // True if the member is whitelisted
    uint256 principal; // Principal amount
    uint256 accrualTs; // Timestamp of the last accrual
    uint256 totalOriginationFee;
    uint256 totalInterest;
  }

  /// @notice Roll data struct
  struct Roll {
    uint256 startDate; // Start date of the roll
    uint256 endDate; // End date of the roll
  }

  /// @notice Callback data struct
  struct CallBack {
    bool isCreated; // True if the callback is created
    uint256 timestamp; // Timestamp of the callback
  }

  /// @notice Struct to store lender deposits as separate position
  struct Position {
    uint256 interest; // total interest for entire deposit period
    uint256 startAt; // Timestamp of the deposit
    uint256 endAt; // Timestamp when the interest ends
  }

  /// @notice Struct to avoid stack too deep error
  struct PoolData {
    bool isBulletLoan; // True if the pool is bullet loan, False if the pool is term loan
    address asset;
    uint256 size;
    uint256 tenor;
    uint256 rateMantissa;
    uint256 depositWindow;
  }

  /// @notice Initialize the pool
  /// @dev This function is called only once during the pool creation
  /// @param _borrower - Pool borrower address
  /// @param _spreadRate - Pool protocol spread rate
  /// @param _originationRate - Pool origination fee rate
  /// @param _incrementPerRoll - Pool rolling increment rate of origination fee
  /// @param _penaltyRatePerYear - Pool penalty rate calculated for 1 year
  /// @param _poolData - Pool data struct: asset, size, tenor, rateMantissa, depositWindow
  /// @param _members - Pool members (lenders) addresses encoded in bytes
  function __Pool_init(
    address _borrower,
    uint256 _spreadRate,
    uint256 _originationRate,
    uint256 _incrementPerRoll,
    uint256 _penaltyRatePerYear,
    PoolData calldata _poolData,
    bytes calldata _members
  ) external;

  /// @notice Whitelists lenders
  /// @dev Can be called only by the borrower
  /// @param lenders - Lenders addresses encoded in bytes
  function whitelistLenders(bytes calldata lenders) external returns (bool);

  /// @notice Blacklists lenders
  /// @dev Can be called only by the borrower
  /// @param lenders - Lenders addresses encoded in bytes
  function blacklistLenders(bytes calldata lenders) external returns (bool);

  /// @notice Converts the pool to public
  /// @dev Can be called only by the borrower
  /// @return success - True if the pool is converted to public
  function switchToPublic() external returns (bool success);

  /// @notice Lends funds to the pool
  /// @dev Can be called only by the whitelisted Prime lenders
  /// @param amount - Amount of funds to lend
  /// @return success - True if the funds are lent
  function lend(uint256 amount) external returns (bool success);

  /// @notice Fully repays the lender with the principal and interest
  /// @dev Can be called only by the borrower
  /// @param lender - Lender address
  /// @return success - True if the lender is repaid
  function repay(address lender) external returns (bool success);

  /// @notice Repays all lenders with the principal and interest
  /// @dev Can be called only by the borrower
  /// @return success - True if all lenders are repaid
  function repayAll() external returns (bool success);

  /// @notice Repays interest to the lender
  /// @dev Can be called only by the borrower in monthly loans
  function repayInterest() external;

  /// @notice Creates the callback
  /// @dev Can be called only by the whitelisted Prime lenders
  /// @return success - True if the callback is created by the lender
  function requestCallBack() external returns (bool success);

  /// @notice Cancels the callback
  /// @dev Can be called only by the whitelisted Prime lenders
  /// @return success - True if the callback is cancelled by the lender
  function cancelCallBack() external returns (bool success);

  /// @notice Requests the roll
  /// @dev Can be called only by the borrower
  function requestRoll() external;

  /// @notice Accepts the roll
  /// @dev Can be called only by the whitelisted Prime lenders
  function acceptRoll() external;

  /// @notice Defaults the pool
  /// @dev Can be called only by lender or borrower if time conditions are met
  /// @dev Can be called by governor without time conditions
  function markPoolDefaulted() external;

  /// @notice Closes the pool
  /// @dev Can be called only by the borrower
  /// @return success - True if the pool is closed
  function close() external returns (bool success);

  /// @notice Calculates the total due amount for repayment including interestAccrued, penalty fee and spread for all lenders
  /// @return totalDue - Total due amount for repayment
  function totalDue() external view returns (uint256 totalDue);

  /// @notice Calculates the due amount for repayment including interestAccrued, penalty fee and spread for the lender
  /// @param lender - The address of the lender
  /// @return due - Due amount for repayment
  /// @return spreadFee - Protocol spread fee
  /// @return originationFee - Origination protocol fee
  /// @return penalty - Penalty fee
  function dueOf(
    address lender
  ) external view returns (uint256 due, uint256 spreadFee, uint256 originationFee, uint256 penalty);

  /// @notice Calculates the total interest and penalty amount for the next payment for all lenders
  /// @return totalInterest The interest amount
  function totalDueInterest() external returns (uint256 totalInterest);

  /// @notice Calculates the total interest and penalty for the next payment to the lender
  /// @param lender The lender address
  /// @return due The interest amount
  /// @return spreadFee The spread amount
  /// @return penalty The penalty amount
  function dueInterestOf(
    address lender
  ) external view returns (uint256 due, uint256 spreadFee, uint256 penalty);

  /// @notice Calculates the accrued amount until today, excluding penalty
  /// @param lender - The address of the lender
  /// @return interestAccrued - Accrued amount until today
  function balanceOf(address lender) external view returns (uint256);

  /// @notice When maturity date passed, calculates the penalty fee for the lender
  /// @param lender - The address of the lender
  /// @return penaltyFee - Penalty fee
  function penaltyOf(address lender) external view returns (uint256);

  /// @notice Calculates the next payment timestamp for the borrower
  /// @return payableToTimestamp - The timestamp of the next payment
  function getNextPaymentTimestamp() external view returns (uint256);

  /// @notice Checks if the pool can be defaulted by borrower or lender
  /// @return isAbleToDefault True if the pool can be defaulted
  function canBeDefaulted() external view returns (bool isAbleToDefault);
}