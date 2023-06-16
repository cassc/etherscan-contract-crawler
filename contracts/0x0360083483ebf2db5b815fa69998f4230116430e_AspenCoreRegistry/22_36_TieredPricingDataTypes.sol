// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

interface ITieredPricingDataTypesV0 {
    enum FeeTypes {
        FlatFee,
        Percentage
    }

    struct Tier {
        string name;
        uint256 price;
        address currency;
        FeeTypes feeType;
    }
}