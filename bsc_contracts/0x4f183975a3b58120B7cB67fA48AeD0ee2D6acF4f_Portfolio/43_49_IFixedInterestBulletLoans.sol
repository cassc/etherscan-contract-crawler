// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import { IPortfolio } from "./IPortfolio.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "openzeppelin-contracts/contracts/access/IAccessControl.sol";
import "./ICurrencyConverter.sol";

enum FixedInterestBulletLoanStatus {
    Created, // after create, before start
    Started, // after accept loan
    Repaid, // after repay loan
    Canceled, // after create and canceled
    Defaulted
}

interface IFixedInterestBulletLoans is IAccessControl {
    error NotPortfolio();
    error PortfolioAlreadySet();
    error NotSuitableLoanStatus();
    error NotEqualRepayAmount();
    /// @notice Emitted when a new loan is created

    event Created(uint256 indexed loanId);
    /// @notice Emitted when a loan is started
    event Started(uint256 indexed loanId);

    /// @notice Emitted when a loan is repaid
    event Repaid(uint256 indexed loanId, uint256 amount);

    /// @notice Emitted when a defaulted loan is repaid
    event RepayDefaulted(uint256 indexed loanId, uint256 amount);

    /// @notice Emitted when a loan is marked as defaulted
    event Defaulted(uint256 indexed loanId);

    /// @notice Emitted when a loan is canceled
    event Canceled(uint256 indexed loanId);

    /// @notice Emitted when a loan status is changed
    event LoanStatusChanged(uint256 indexed loanId, FixedInterestBulletLoanStatus newStatus);

    struct LoanMetadata {
        uint256 krwPrincipal;
        uint256 usdPrincipal;
        uint256 usdRepaid;
        uint256 interestRate; // Use basis point i.e. 10000 = 100%
        address recipient;
        address collateral;
        uint256 collateralId;
        uint256 startDate;
        uint256 duration;
        FixedInterestBulletLoanStatus status; // uint8
        IERC20 asset;
    }

    struct IssueLoanInputs {
        uint256 krwPrincipal;
        uint256 interestRate; // Use basis point i.e. 10000 = 100%
        address recipient;
        address collateral;
        uint256 collateralId;
        uint256 duration;
        IERC20 asset;
    }

    /// @notice Issue a new loan with the specified parameters
    /// @param loanInputs The input parameters for the new loan
    /// @return The ID of the newly created loan
    function issueLoan(IssueLoanInputs calldata loanInputs) external returns (uint256);

    /// @notice Start a loan with the specified ID
    /// @dev The loan must be in the Created status and the caller must be the portfolio contract
    /// @param loanId The ID of the loan to start
    /// @return principal The borrowed principal amount of the loan in USD
    function startLoan(uint256 loanId) external returns (uint256 principal);

    /// @notice Retrieve loan data for a specific loan ID
    /// @param loanId The ID of the loan
    /// @return The loan metadata as a LoanMetadata struct
    function loanData(uint256 loanId) external view returns (LoanMetadata memory);

    /// @notice Repay a loan with the specified ID and amount
    /// @dev The loan must be in the Started status and the caller must be the portfolio contract
    /// @param loanId The ID of the loan to repay
    /// @param usdAmount The amount to repay in USD
    function repayLoan(uint256 loanId, uint256 usdAmount) external;

    /// @notice Repay a defaulted loan with the specified ID and amount
    /// @dev The loan must be in the Defaulted status and the caller must be the portfolio contract
    /// @param loanId The ID of the defaulted loan to repay
    /// @param usdAmount The amount to repay in USD
    function repayDefaultedLoan(uint256 loanId, uint256 usdAmount) external;

    /// @notice Cancel a loan with the specified ID
    /// @dev The loan must be in the Created status and the caller must be the portfolio contract
    /// @param loanId The ID of the loan to cancel
    function cancelLoan(uint256 loanId) external;

    /// @notice Mark a loan as defaulted with the specified ID
    /// @dev The loan must be in the Started status and the caller must be the portfolio contract
    /// @param loanId The ID of the loan to mark as defaulted
    function markLoanAsDefaulted(uint256 loanId) external;

    /// @notice Get the recipient address of a loan with the specified ID
    /// @param loanId The ID of the loan
    /// @return The recipient address
    function getRecipient(uint256 loanId) external view returns (address);

    /// @notice Get the status of a loan with the specified ID
    /// @param loanId The ID of the loan
    /// @return The loan status as a FixedInterestBulletLoanStatus enum value
    function getStatus(uint256 loanId) external view returns (FixedInterestBulletLoanStatus);

    /// @notice Check if a loan with the specified ID is overdue
    /// @param loanId The ID of the loan
    /// @return A boolean value indicating if the loan is overdue
    function isOverdue(uint256 loanId) external view returns (bool);

    /// @notice Get the total number of loans
    /// @return The total number of loans
    function getLoansLength() external view returns (uint256);

    /// @notice Calculate the loan value at the current timestamp
    /// @param loanId The ID of the loan
    /// @return loan value. It remains the same after loan.endDate
    function currentUsdValue(uint256 loanId) external view returns (uint256);

    /// @notice Calculate the amount to repay. It is the same regardless of the repaying time.
    /// @param loanId The ID of the loan
    /// @return repayment amount
    function expectedUsdRepayAmount(uint256 loanId) external view returns (uint256);

    /// @notice Set the portfolio contract
    /// @dev The caller must have the manager role
    /// @param _portfolio The address of the portfolio contract
    function setPortfolio(IPortfolio _portfolio) external;

    /// @notice Set the currency converter contract
    /// @dev The caller must have the manager role
    /// @param _currencyConverter The address of the currency converter contract
    function setCurrencyConverter(ICurrencyConverter _currencyConverter) external;
}