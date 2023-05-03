// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import { IFixedInterestBulletLoans, FixedInterestBulletLoanStatus } from "./IFixedInterestBulletLoans.sol";

struct AddLoanParams {
    address recipient;
    uint256 krwPrincipal;
    uint256 interestRate;
    address collateral;
    uint256 collateralId;
    uint256 duration;
}

interface ILoansManager {
    /// @notice Emitted when a loan is added
    event LoanAdded(uint256 indexed loanId);

    /// @notice Emitted when a loan is funded
    event LoanFunded(uint256 indexed loanId);

    /// @notice Emitted when a loan is repaid
    event LoanRepaid(uint256 indexed loanId, uint256 amount);

    /// @notice Emitted when a loan is canceled
    event LoanCanceled(uint256 indexed loanId);

    /// @notice Emitted when a loan is defaulted
    event LoanDefaulted(uint256 indexed loanId);

    /// @notice Emitted when a active loan is removed
    event ActiveLoanRemoved(uint256 indexed loanId, FixedInterestBulletLoanStatus indexed status);

    /// @notice Thrown when loanId is not valid or doesn't exist in the issuedLoanIds mapping
    error InvalidLoanId();
    /// @notice Thrown when there are insufficient funds in the contract to fund a loan
    error InSufficientFund();
    /// @notice Thrown when the recipient address is invalid
    error InvalidRecipient();

    /// @param loanId Loan id
    /// @return Whether a loan with the given loanId was issued by this contract
    function issuedLoanIds(uint256 loanId) external view returns (bool);

    /// @return FixedInterestBulletLoans contract
    function fixedInterestBulletLoans() external view returns (IFixedInterestBulletLoans);
}