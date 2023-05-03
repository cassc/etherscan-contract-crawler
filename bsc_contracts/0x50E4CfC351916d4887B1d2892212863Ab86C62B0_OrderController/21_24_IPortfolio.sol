// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import { ITranchePool } from "./ITranchePool.sol";
import { IAccessControl } from "openzeppelin-contracts/contracts/access/IAccessControl.sol";
import { AddLoanParams, ILoansManager } from "./ILoansManager.sol";

enum Status {
    Preparation,
    Live,
    Stopped,
    SeniorClosed,
    EquityClosed
}

struct TrancheData {
    /// @dev
    uint256 initialAssets;
    /// @dev The APR expected to be granted at the end of the portfolio Live phase (in BPS)
    uint128 targetApr;
    /// @dev The minimum required ratio of the sum of subordinate tranches assets to the tranche assets (in BPS)
    /// It must be floored. e.g. 0.42857 -> 4285 (decimal 4)
    uint128 minSubordinateRatio;
}

struct TrancheInitData {
    /// @dev Address of the tranche vault
    ITranchePool tranche;
    /// @dev The APR expected to be granted at the end of the portfolio Live phase (in BPS)
    uint128 targetApr;
    /// @dev The minimum required ratio of the sum of subordinate tranches assets to the tranche assets (in BPS)
    uint128 minSubordinateRatio;
}

interface IPortfolio {
    error NotTranche();
    error NotGovernance();
    error NotManagerOrCollateralOwner();
    error EquityAprNotZero();
    error ActiveLoansExist();
    error AlreadyStarted();
    error NotReadyToCloseSenior();
    error NotFullyFunded();
    error NotReadyToCloseEquity();
    error AddLoanNotAllowed();
    error FundLoanNotAllowed();
    error RepayLoanNotAllowed();
    error RepayDefaultedLoanNotAllowed();

    error StopPortfolioWithInvalidStatus();
    error StopPortfolioWithInvalidValues();

    error RestartPortfolioWithInvalidStatus();
    error RestartPortfolioWithInvalidValues();
    error RestartPortfolioOverDuration();

    error DepositInvalidStatus();

    event PortfolioStatusChanged(Status status);

    /// @notice Returns the address of the tranche pool contract
    function tranches(uint256 index) external view returns (ITranchePool);

    /// @notice Returns current portfolio status
    function status() external view returns (Status);

    /// @notice Returns the timestamp when the portfolio started
    function startTimestamp() external view returns (uint40);

    /// @notice calculate each tranche values based only on the current assets.
    /// @dev It does not take account of loans value.
    /// @return Array of current tranche values
    function calculateWaterfall() external view returns (uint256[] memory);

    function calculateWaterfallForTranche(uint256 waterfallIndex) external view returns (uint256);

    /// @notice calculate each tranche values given the (current assets + loans value).
    function calculateWaterfallWithLoans() external view returns (uint256[] memory);

    function calculateWaterfallWithLoansForTranche(uint256 waterfallIndex) external view returns (uint256);

    /// @notice calculate the total value of all active loans in the contract.
    function loansValue() external view returns (uint256);

    /// @notice get token balance of this contract
    function getTokenBalance() external view returns (uint256);

    /// @notice get assumed current values
    /// @return equityValue The value of equity tranche
    /// @return fixedRatePoolValue The value of fixed rate pool tranches
    /// @return overdueValue The value of overdue loans
    function getAssumedCurrentValues()
        external
        view
        returns (uint256 equityValue, uint256 fixedRatePoolValue, uint256 overdueValue);

    /// @notice Starts the portfolio to issue loans.
    /// @dev
    /// - changes the state to Live
    /// - gathers assets to the portfolio from every tranche.
    /// @custom:role - manager
    function start() external;

    /// @notice Allow the senior tranche to withdraw.
    /// @dev
    /// - changes the state to SeniorClosed
    /// - Distribute the remaining assets to the senior tranche.
    /// @custom:role - manager
    function closeSenior() external;

    /// @notice Allow the equity tranche to withdraw.
    /// @dev
    /// - changes the state to EquityClosed
    /// - Distribute the remaining assets to the equity tranche.
    /// @custom:role - manager
    function closeEquity() external;

    /// @notice Create loan
    /// @param params Loan params
    /// @custom:status - Preparation, Live
    /// @custom:role - manager || collateral owner
    function addLoan(AddLoanParams calldata params) external returns (uint256 loanId);

    /// @notice Fund the loan
    /// @param loanId Loan id
    /// @custom:status - Live
    /// @custom:role - governance
    function fundLoan(uint256 loanId) external returns (uint256 principal);

    /// @notice Repay the loan
    /// @param loanId Loan id
    /// @custom:status - Live || SeniorClosed || Stopped
    /// @custom:role - all
    function repayLoan(uint256 loanId) external returns (uint256 amount);

    /// @notice Repay the loan
    /// @param loanId Loan id
    /// @param amount amount
    /// @custom:status - Live || SeniorClosed || Stopped
    /// @custom:role - manager
    function repayDefaultedLoan(uint256 loanId, uint256 amount) external;

    /// @notice Cancel the loan
    /// @param loanId Loan id
    /// @custom:role - manager
    function cancelLoan(uint256 loanId) external;

    /// @notice Cancel the loan
    /// @param loanId Loan id
    /// @custom:status - All (as long as the loan exists)
    /// @custom:role - manager
    function markLoanAsDefaulted(uint256 loanId) external;

    /// @notice Increase the current token balance of the portfolio
    /// @dev This function is used to track the token balance of the portfolio. Only the tranche pool contract can call
    /// @param amount Amount to increase
    /// @custom:role - tranchePool
    function increaseTokenBalance(uint256 amount) external;
}