// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./OevDapiServer.sol";
import "./BeaconUpdatesWithSignedData.sol";
import "./interfaces/IApi3ServerV1.sol";

/// @title First version of the contract that API3 uses to serve data feeds
/// @notice Api3ServerV1 serves data feeds in the form of Beacons, Beacon sets,
/// dAPIs, with optional OEV support for all of these.
/// The base Beacons are only updateable using signed data, and the Beacon sets
/// are updateable based on the Beacons, optionally using PSP. OEV proxy
/// Beacons and Beacon sets are updateable using OEV-signed data.
/// Api3ServerV1 does not support Beacons to be updated using RRP or PSP.
contract Api3ServerV1 is
    OevDapiServer,
    BeaconUpdatesWithSignedData,
    IApi3ServerV1
{
    /// @param _accessControlRegistry AccessControlRegistry contract address
    /// @param _adminRoleDescription Admin role description
    /// @param _manager Manager address
    constructor(
        address _accessControlRegistry,
        string memory _adminRoleDescription,
        address _manager
    ) OevDapiServer(_accessControlRegistry, _adminRoleDescription, _manager) {}

    /// @notice Reads the data feed with ID
    /// @param dataFeedId Data feed ID
    /// @return value Data feed value
    /// @return timestamp Data feed timestamp
    function readDataFeedWithId(
        bytes32 dataFeedId
    ) external view override returns (int224 value, uint32 timestamp) {
        return _readDataFeedWithId(dataFeedId);
    }

    /// @notice Reads the data feed with dAPI name hash
    /// @param dapiNameHash dAPI name hash
    /// @return value Data feed value
    /// @return timestamp Data feed timestamp
    function readDataFeedWithDapiNameHash(
        bytes32 dapiNameHash
    ) external view override returns (int224 value, uint32 timestamp) {
        return _readDataFeedWithDapiNameHash(dapiNameHash);
    }

    /// @notice Reads the data feed as the OEV proxy with ID
    /// @param dataFeedId Data feed ID
    /// @return value Data feed value
    /// @return timestamp Data feed timestamp
    function readDataFeedWithIdAsOevProxy(
        bytes32 dataFeedId
    ) external view override returns (int224 value, uint32 timestamp) {
        return _readDataFeedWithIdAsOevProxy(dataFeedId);
    }

    /// @notice Reads the data feed as the OEV proxy with dAPI name hash
    /// @param dapiNameHash dAPI name hash
    /// @return value Data feed value
    /// @return timestamp Data feed timestamp
    function readDataFeedWithDapiNameHashAsOevProxy(
        bytes32 dapiNameHash
    ) external view override returns (int224 value, uint32 timestamp) {
        return _readDataFeedWithDapiNameHashAsOevProxy(dapiNameHash);
    }

    function dataFeeds(
        bytes32 dataFeedId
    ) external view override returns (int224 value, uint32 timestamp) {
        DataFeed storage dataFeed = _dataFeeds[dataFeedId];
        (value, timestamp) = (dataFeed.value, dataFeed.timestamp);
    }

    function oevProxyToIdToDataFeed(
        address proxy,
        bytes32 dataFeedId
    ) external view override returns (int224 value, uint32 timestamp) {
        DataFeed storage dataFeed = _oevProxyToIdToDataFeed[proxy][dataFeedId];
        (value, timestamp) = (dataFeed.value, dataFeed.timestamp);
    }
}