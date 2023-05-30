// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDataFeedServer.sol";

interface IBeaconUpdatesWithSignedData is IDataFeedServer {
    function updateBeaconWithSignedData(
        address airnode,
        bytes32 templateId,
        uint256 timestamp,
        bytes calldata data,
        bytes calldata signature
    ) external returns (bytes32 beaconId);
}