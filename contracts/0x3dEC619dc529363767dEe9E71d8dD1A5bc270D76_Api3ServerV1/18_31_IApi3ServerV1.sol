// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IOevDapiServer.sol";
import "./IBeaconUpdatesWithSignedData.sol";

interface IApi3ServerV1 is IOevDapiServer, IBeaconUpdatesWithSignedData {
    function readDataFeedWithId(
        bytes32 dataFeedId
    ) external view returns (int224 value, uint32 timestamp);

    function readDataFeedWithDapiNameHash(
        bytes32 dapiNameHash
    ) external view returns (int224 value, uint32 timestamp);

    function readDataFeedWithIdAsOevProxy(
        bytes32 dataFeedId
    ) external view returns (int224 value, uint32 timestamp);

    function readDataFeedWithDapiNameHashAsOevProxy(
        bytes32 dapiNameHash
    ) external view returns (int224 value, uint32 timestamp);

    function dataFeeds(
        bytes32 dataFeedId
    ) external view returns (int224 value, uint32 timestamp);

    function oevProxyToIdToDataFeed(
        address proxy,
        bytes32 dataFeedId
    ) external view returns (int224 value, uint32 timestamp);
}