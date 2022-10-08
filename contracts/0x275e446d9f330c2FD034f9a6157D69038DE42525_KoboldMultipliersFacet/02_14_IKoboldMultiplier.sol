// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.17;   
    struct KoboldStakingMultiplier {
        uint price;
        uint multiplier; //5  = 5%
        bool isAvailableForPurchase;
        uint maxQuantity;
        uint quantitySold;
        string name;
    }