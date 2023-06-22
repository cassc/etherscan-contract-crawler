// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library DataTypes {
    struct BoostItem {
        address owner;
        uint32 id;
        uint40 lockTime;
        bool released;
    }
    struct ViewBoostItem {
        address owner;
        uint32 id;
        uint40 lockTime;
        uint40 unlockTime;
        bool released;
    }
// 32 
// 20, 4, 5, 1

    struct BoostInfo {
        uint curTier;
        uint curPumpRate;
        uint nextTier;
        uint nextPumpRate;
        uint dgaRequired;
        uint totalPumped;
    }
    
}