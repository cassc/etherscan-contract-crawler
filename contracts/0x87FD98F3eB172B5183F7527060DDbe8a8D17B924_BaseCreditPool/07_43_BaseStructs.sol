// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../interfaces/IFeeManager.sol";
import "hardhat/console.sol";

library BaseStructs {
    /**
     * @notice CreditRecord stores the overall info and status about a credit.
     * @dev amounts are stored in uint96, all counts are stored in uint16
     * @dev each struct can have no more than 13 elements.
     */
    struct CreditRecord {
        uint96 unbilledPrincipal; // the amount of principal not included in the bill
        uint64 dueDate; // the due date of the next payment
        // correction is the adjustment of interest over or under-counted because of drawdown
        // or principal payment in the middle of a billing period
        int96 correction;
        uint96 totalDue; // the due amount of the next payment
        uint96 feesAndInterestDue; // interest and fees due for the next payment
        uint16 missedPeriods; // # of consecutive missed payments, for default processing
        uint16 remainingPeriods; // # of payment periods until the maturity of the credit line
        CreditState state; // status of the credit line
    }

    struct CreditRecordStatic {
        uint96 creditLimit; // the limit of the credit line
        uint16 aprInBps; // annual percentage rate in basis points, 3.75% is represented as 375
        uint16 intervalInDays; // # of days in one billing period
        uint96 defaultAmount; // the amount that has been defaulted.
    }

    /**
     * @notice ReceivableInfo stores receivable used for credits.
     * @dev receivableParam is used to store info such as NFT tokenId
     */
    struct ReceivableInfo {
        address receivableAsset;
        uint96 receivableAmount;
        uint256 receivableParam;
    }

    struct FlagedPaymentRecord {
        address paymentReceiver;
        uint256 amount;
    }

    enum CreditState {
        Deleted,
        Requested,
        Approved,
        GoodStanding,
        Delayed,
        Defaulted
    }
    enum PaymentStatus {
        NotReceived,
        ReceivedNotVerified,
        ReceivedAndVerified
    }
}