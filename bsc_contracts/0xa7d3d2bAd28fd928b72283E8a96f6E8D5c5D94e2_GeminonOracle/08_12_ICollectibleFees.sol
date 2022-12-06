// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/**
* @title ICollectibleFees
* @author Geminon Protocol
* @notice Interface for smart contracts whose fees have
* to be collected by the FeeCollector contract.
*/
interface ICollectibleFees {
    function setCollector(address feesCollector) external;
    function collectFees() external returns(uint256);
}