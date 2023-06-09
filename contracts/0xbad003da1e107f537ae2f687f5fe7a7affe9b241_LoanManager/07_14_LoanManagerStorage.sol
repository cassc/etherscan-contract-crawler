// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { ILoanManagerStorage } from "./interfaces/ILoanManagerStorage.sol";

abstract contract LoanManagerStorage is ILoanManagerStorage {

    struct Impairment {
        uint40 impairedDate;        // Slot 1: uint40 - Until year 36,812.
        bool   impairedByGovernor;  //         bool
    }

    struct Payment {
        uint24  platformManagementFeeRate;  // Slot 1: uint24  - max = 1.6e7 (1600%)
        uint24  delegateManagementFeeRate;  //         uint24  - max = 1.6e7 (1600%)
        uint40  startDate;                  //         uint40  - Until year 36,812.
        uint168 issuanceRate;               //         uint168 - max = 3.7e50 (3.2e10 * 1e18 / day)
    }

    uint256 internal _locked;  // Used when checking for reentrancy.

    uint40  public override domainStart;        // Slot 1: uint40  - Until year 36,812.
    uint112 public override accountedInterest;  //         uint112 - max = 5.1e33
    uint128 public override principalOut;       // Slot 2: uint128 - max = 3.4e38
    uint128 public override unrealizedLosses;   //         uint128 - max = 3.4e38
    uint256 public override issuanceRate;       // Slot 3: uint256 - max = 1.1e77

    // NOTE: Addresses below uints to preserve full storage slots
    address public override fundsAsset;
    address public override poolManager;

    mapping(address => Impairment) public override impairmentFor;

    mapping(address => Payment) public override paymentFor;

}