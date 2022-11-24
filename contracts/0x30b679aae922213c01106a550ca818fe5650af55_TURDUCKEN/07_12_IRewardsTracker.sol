pragma solidity 0.8.4;

// SPDX-License-Identifier: Apache-2.0

interface IRewardsTracker {
    
    function addAllocation(uint identifier) external payable;
}