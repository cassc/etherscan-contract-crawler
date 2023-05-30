// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./OevDataFeedServer.sol";
import "./DapiServer.sol";
import "./interfaces/IOevDapiServer.sol";

/// @title Contract that serves OEV dAPIs
contract OevDapiServer is OevDataFeedServer, DapiServer, IOevDapiServer {
    /// @param _accessControlRegistry AccessControlRegistry contract address
    /// @param _adminRoleDescription Admin role description
    /// @param _manager Manager address
    constructor(
        address _accessControlRegistry,
        string memory _adminRoleDescription,
        address _manager
    ) DapiServer(_accessControlRegistry, _adminRoleDescription, _manager) {}

    /// @notice Reads the data feed as the OEV proxy with dAPI name hash
    /// @param dapiNameHash dAPI name hash
    /// @return value Data feed value
    /// @return timestamp Data feed timestamp
    function _readDataFeedWithDapiNameHashAsOevProxy(
        bytes32 dapiNameHash
    ) internal view returns (int224 value, uint32 timestamp) {
        bytes32 dataFeedId = dapiNameHashToDataFeedId[dapiNameHash];
        require(dataFeedId != bytes32(0), "dAPI name not set");
        DataFeed storage oevDataFeed = _oevProxyToIdToDataFeed[msg.sender][
            dataFeedId
        ];
        DataFeed storage dataFeed = _dataFeeds[dataFeedId];
        if (oevDataFeed.timestamp > dataFeed.timestamp) {
            (value, timestamp) = (oevDataFeed.value, oevDataFeed.timestamp);
        } else {
            (value, timestamp) = (dataFeed.value, dataFeed.timestamp);
        }
        require(timestamp > 0, "Data feed not initialized");
    }
}