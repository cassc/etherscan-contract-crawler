// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokeManager {
    function currentCycleIndex() external view returns (uint256);

    // NOTE: THIS IS ONLY FOR TESTS PURPOSE, THIS FUNCTION DOES NOT EXIST IN REALITY
    function incrementCycleIndex(uint256 _value) external;
}