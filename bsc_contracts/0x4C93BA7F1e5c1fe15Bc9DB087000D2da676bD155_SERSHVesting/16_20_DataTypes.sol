// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library DataTypes {
    
    enum VestingCategory {
        None, 
        Seed, 
        PS1, 
        PS2, 
        PR,
        TM,
        AD,
        EM,
        TR,
        ICO
    }

    struct VestingPlan {
        uint cliffMonths;
        uint linearMonths;
        uint256 tgeRate;
        uint256 cliffRate;
        uint256 vestingRate;
        
    }

}