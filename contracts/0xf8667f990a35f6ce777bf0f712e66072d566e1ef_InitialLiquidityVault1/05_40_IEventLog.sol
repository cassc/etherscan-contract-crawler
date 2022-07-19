//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;


/// @title IEventLog
interface IEventLog {

    /// @dev logEvent function
    /// @param contractNameHash contractNameHash
    /// @param eventNameHash eventNameHash
    /// @param contractAddress contractAddress
    /// @param data data
    function logEvent(
        bytes32 contractNameHash,
        bytes32 eventNameHash,
        address contractAddress,
        bytes memory data
        )
        external;
}