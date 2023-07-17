//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library StructLibrary {
    
    struct eachTransaction {
        
        uint128 stakeAmount;
        uint128 depositTime;
        uint128 fullWithdrawlTime;
        uint128 lastClaimTime;
        bool accumulated;
        
        
    }

    struct StakeTypeData {
        uint128 stakeType;
        uint128 stakePeriod;
        uint128 depositFees;
        uint128 withdrawlFees;
        uint128 rewardRate;
        uint128 totalStakedIn;
        bool isActive;
    }

    
}