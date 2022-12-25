// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface GreenMachineMinerConfigIface {
    //Apply ROI event boost to the amount specified
    function applyROIEventBoost(uint256 amount) external view returns (uint256); 
    //Is needed to update CA timestamps?
    function needUpdateEventBoostTimestamps() external view returns (bool); 
    //Update CA timestamps
    function updateEventsBoostTimestamps() external; 
}