// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;
import {BaseStructs as BS} from "../libraries/BaseStructs.sol";

interface ICredit {
    /// Approves a credit line request
    function approveCredit(
        address borrower,
        uint256 creditLimit,
        uint256 intervalInDays,
        uint256 remainingPeriods,
        uint256 aprInBps
    ) external;

    /// Updating the credit limit of an existing credit line
    function changeCreditLine(address _borrower, uint256 newLine) external;

    /// Makes drawdown from an approved credit line
    function drawdown(uint256 _borrowAmount) external;

    /// Extends the validity period of the credit line
    function extendCreditLineDuration(address borrower, uint256 numOfPeriods) external;

    /**
     * @notice Makes a payment towardds an open credit line
     * @param _borrower the borrower
     * @param _amount the payment amount
     * @param amountPaid the amount actually paid
     * @return amountPaid the actuall amount paid to the contract. When the tendered
     * amount is larger than the payoff amount, the contract only accepts the payoff amount.
     * @return paidoff a flag indciating whether the account has been paid off.
     */
    function makePayment(address _borrower, uint256 _amount)
        external
        returns (uint256 amountPaid, bool paidoff);

    /**
     * @notice Refreshes the account status
     * @param borrower the address of the borrower
     * @return cr the refreshed credit record of the borrower.
     */
    function refreshAccount(address borrower) external returns (BS.CreditRecord memory cr);

    /**
     * @notice Requests a credit line
     * @param _creditLimit the limit of the credit line
     * @param  _intervalInDays the time interval between two payments
     * @param _numOfPayments total number of payment cycles for the credit line
     */
    function requestCredit(
        uint256 _creditLimit,
        uint256 _intervalInDays,
        uint256 _numOfPayments
    ) external;

    /**
     * @notice Triggers default for the credit line owned by the borrower
     * @param borrower the address of the borrower
     * @return losses the write off by the pool because of this default
     */
    function triggerDefault(address borrower) external returns (uint256 losses);

    /// Gets the approval status of the credit line for the borrower
    function isApproved(address borrower) external view returns (bool);

    /// Checks if the credit line owned by the borrower is ready for default
    function isDefaultReady(address borrower) external view returns (bool);

    /// Checks if the credit line owned by the borrower is late in payments
    function isLate(address borrower) external view returns (bool);
}