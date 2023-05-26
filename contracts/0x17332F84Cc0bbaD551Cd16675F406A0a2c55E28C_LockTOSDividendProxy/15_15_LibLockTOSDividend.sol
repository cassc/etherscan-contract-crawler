// SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;


library LibLockTOSDividend {
    struct Distribution {
        bool exists;
        uint256 totalDistribution;
        uint256 lastBalance;
        mapping (uint256 => uint256) tokensPerWeek;
        mapping (uint256 => uint256) claimStartWeeklyEpoch;
    } 
}