// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDapiReader {
    function dapiServer() external view returns (address);
}

/// @dev We use the part of the interface that will persist between
/// DapiServer versions
interface IBaseDapiServer {
    function readDataFeedWithId(bytes32 dataFeedId)
        external
        view
        returns (int224 value, uint32 timestamp);

    function readDataFeedWithDapiName(bytes32 dapiName)
        external
        view
        returns (int224 value, uint32 timestamp);
}