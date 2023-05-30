// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../access-control-registry/AccessControlRegistryAdminnedWithManager.sol";
import "./DataFeedServer.sol";
import "./interfaces/IDapiServer.sol";

/// @title Contract that serves dAPIs mapped to Beacons and Beacon sets
/// @notice Beacons and Beacon sets are addressed by immutable IDs. Although
/// this is trust-minimized, it requires users to manage the ID of the data
/// feed they are using. For when the user does not want to do this, dAPIs can
/// be used as an abstraction layer. By using a dAPI, the user delegates this
/// responsibility to dAPI management. It is important for dAPI management to
/// be restricted by consensus rules (by using a multisig or a DAO) and similar
/// trustless security mechanisms.
contract DapiServer is
    AccessControlRegistryAdminnedWithManager,
    DataFeedServer,
    IDapiServer
{
    /// @notice dAPI name setter role description
    string public constant override DAPI_NAME_SETTER_ROLE_DESCRIPTION =
        "dAPI name setter";

    /// @notice dAPI name setter role
    bytes32 public immutable override dapiNameSetterRole;

    /// @notice dAPI name hash mapped to the data feed ID
    mapping(bytes32 => bytes32) public override dapiNameHashToDataFeedId;

    /// @param _accessControlRegistry AccessControlRegistry contract address
    /// @param _adminRoleDescription Admin role description
    /// @param _manager Manager address
    constructor(
        address _accessControlRegistry,
        string memory _adminRoleDescription,
        address _manager
    )
        AccessControlRegistryAdminnedWithManager(
            _accessControlRegistry,
            _adminRoleDescription,
            _manager
        )
    {
        dapiNameSetterRole = _deriveRole(
            _deriveAdminRole(manager),
            DAPI_NAME_SETTER_ROLE_DESCRIPTION
        );
    }

    /// @notice Sets the data feed ID the dAPI name points to
    /// @dev While a data feed ID refers to a specific Beacon or Beacon set,
    /// dAPI names provide a more abstract interface for convenience. This
    /// means a dAPI name that was pointing to a Beacon can be pointed to a
    /// Beacon set, then another Beacon set, etc.
    /// @param dapiName Human-readable dAPI name
    /// @param dataFeedId Data feed ID the dAPI name will point to
    function setDapiName(
        bytes32 dapiName,
        bytes32 dataFeedId
    ) external override {
        require(dapiName != bytes32(0), "dAPI name zero");
        require(
            msg.sender == manager ||
                IAccessControlRegistry(accessControlRegistry).hasRole(
                    dapiNameSetterRole,
                    msg.sender
                ),
            "Sender cannot set dAPI name"
        );
        dapiNameHashToDataFeedId[
            keccak256(abi.encodePacked(dapiName))
        ] = dataFeedId;
        emit SetDapiName(dataFeedId, dapiName, msg.sender);
    }

    /// @notice Returns the data feed ID the dAPI name is set to
    /// @param dapiName dAPI name
    /// @return Data feed ID
    function dapiNameToDataFeedId(
        bytes32 dapiName
    ) external view override returns (bytes32) {
        return dapiNameHashToDataFeedId[keccak256(abi.encodePacked(dapiName))];
    }

    /// @notice Reads the data feed with dAPI name hash
    /// @param dapiNameHash dAPI name hash
    /// @return value Data feed value
    /// @return timestamp Data feed timestamp
    function _readDataFeedWithDapiNameHash(
        bytes32 dapiNameHash
    ) internal view returns (int224 value, uint32 timestamp) {
        bytes32 dataFeedId = dapiNameHashToDataFeedId[dapiNameHash];
        require(dataFeedId != bytes32(0), "dAPI name not set");
        DataFeed storage dataFeed = _dataFeeds[dataFeedId];
        (value, timestamp) = (dataFeed.value, dataFeed.timestamp);
        require(timestamp > 0, "Data feed not initialized");
    }
}