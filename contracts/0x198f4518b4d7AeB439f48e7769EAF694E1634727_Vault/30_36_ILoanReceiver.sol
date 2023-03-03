// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Interface containing callbacks for smart contract loan holders
 * @notice Lending platforms should detect if a lender implements this
 * interface and call it on loan repayment.
 */
interface ILoanReceiver {
    /**
     * @notice Callback on loan repaid
     * @param noteToken Note token contract
     * @param loanId Loan ID
     */
    function onLoanRepaid(address noteToken, uint256 loanId) external;

    /**
     * @notice Callback on loan expired
     * @param noteToken Note token contract
     * @param loanId Loan ID
     */
    function onLoanExpired(address noteToken, uint256 loanId) external;
}