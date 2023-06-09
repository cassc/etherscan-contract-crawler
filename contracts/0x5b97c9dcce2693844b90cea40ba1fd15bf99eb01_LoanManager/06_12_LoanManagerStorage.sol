// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { ILoanManagerStorage } from "../interfaces/ILoanManagerStorage.sol";

abstract contract LoanManagerStorage is ILoanManagerStorage {

    struct LiquidationInfo {
        bool    triggeredByGovernor;  // Slot 1: bool    -  1 bytes
        uint128 principal;            //         uint128 - 16 bytes: max = 3.4e38
        uint120 interest;             //         uint120 - 15 bytes: max = 1.7e38
        uint256 lateInterest;         // Slot 2: uint256 - 32 bytes: max = 1.1e77
        uint96  platformFees;         // Slot 3: uint96  - 12 bytes: max = 7.9e28 (>79b units at 1e18)
        address liquidator;           //         address - 20 bytes
    }

    struct PaymentInfo {
        uint24  platformManagementFeeRate;  // Slot 1: uint24  -  3 bytes: max = 1.6e7  (1600%)
        uint24  delegateManagementFeeRate;  //         uint24  -  3 bytes: max = 1.6e7  (1600%)
        uint48  startDate;                  //         uint48  -  6 bytes: max = 2.8e14 (>8m years)
        uint48  paymentDueDate;             //         uint48  -  6 bytes: max = 2.8e14 (>8m years)
        uint128 incomingNetInterest;        // Slot 2: uint128 - 16 bytes: max = 3.4e38
        uint128 refinanceInterest;          //         uint128 - 16 bytes: max = 3.4e38
        uint256 issuanceRate;               // Slot 3: uint256 - 32 bytes: max = 1.1e77
    }

    struct SortedPayment {
        uint24 previous;        // uint24 - 3 bytes: max = 1.6e7
        uint24 next;            // uint24 - 3 bytes: max = 1.6e7
        uint48 paymentDueDate;  // uint48 - 6 bytes: max = 2.8e14 (>8m years)
    }

    uint256 internal _locked;  // Used when checking for reentrancy.

    uint24  public override paymentCounter;              // Slot 1: uint24  -  3 bytes: max = 1.6e7
    uint24  public override paymentWithEarliestDueDate;  //         uint24  -  3 bytes: max = 1.6e7
    uint48  public override domainStart;                 //         uint48  -  6 bytes: max = 2.8e14  (>8m years)
    uint48  public override domainEnd;                   //         uint48  -  6 bytes: max = 2.8e14  (>8m years)
    uint112 public override accountedInterest;           //         uint112 - 14 bytes: max = 5.19e33
    uint128 public override principalOut;                // Slot 2: uint128 - 16 bytes: max = 3.4e38
    uint128 public override unrealizedLosses;            //         uint128 - 16 bytes: max = 3.4e38
    uint256 public override issuanceRate;                // Slot 3: uint256 - 32 bytes: max = 1.1e77

    // NOTE: Addresses below uints to preserve full storage slots
    address public override fundsAsset;

    address internal __deprecated_loanTransferAdmin;
    address internal __deprecated_pool;

    address public override poolManager;

    mapping(address => uint24) public override paymentIdOf;

    mapping(address => uint256) public override allowedSlippageFor;
    mapping(address => uint256) public override minRatioFor;

    mapping(address => LiquidationInfo) public override liquidationInfo;

    mapping(uint256 => PaymentInfo) public override payments;

    mapping(uint256 => SortedPayment) public override sortedPayments;

}