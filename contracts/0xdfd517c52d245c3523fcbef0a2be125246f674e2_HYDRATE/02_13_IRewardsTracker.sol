pragma solidity ^0.8.17;

// SPDX-License-Identifier: Apache-2.0

interface IRewardsTracker {
    
    function addAllocation(uint identifier) external payable;
}