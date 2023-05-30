// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../access-control-registry/interfaces/IAccessControlRegistryAdminnedWithManager.sol";
import "./IDataFeedServer.sol";

interface IDapiServer is
    IAccessControlRegistryAdminnedWithManager,
    IDataFeedServer
{
    event SetDapiName(
        bytes32 indexed dataFeedId,
        bytes32 indexed dapiName,
        address sender
    );

    function setDapiName(bytes32 dapiName, bytes32 dataFeedId) external;

    function dapiNameToDataFeedId(
        bytes32 dapiName
    ) external view returns (bytes32);

    // solhint-disable-next-line func-name-mixedcase
    function DAPI_NAME_SETTER_ROLE_DESCRIPTION()
        external
        view
        returns (string memory);

    function dapiNameSetterRole() external view returns (bytes32);

    function dapiNameHashToDataFeedId(
        bytes32 dapiNameHash
    ) external view returns (bytes32 dataFeedId);
}