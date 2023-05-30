// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../utils/interfaces/IExtendedSelfMulticall.sol";

interface IDataFeedServer is IExtendedSelfMulticall {
    event UpdatedBeaconWithSignedData(
        bytes32 indexed beaconId,
        int224 value,
        uint32 timestamp
    );

    event UpdatedBeaconSetWithBeacons(
        bytes32 indexed beaconSetId,
        int224 value,
        uint32 timestamp
    );

    function updateBeaconSetWithBeacons(
        bytes32[] memory beaconIds
    ) external returns (bytes32 beaconSetId);
}