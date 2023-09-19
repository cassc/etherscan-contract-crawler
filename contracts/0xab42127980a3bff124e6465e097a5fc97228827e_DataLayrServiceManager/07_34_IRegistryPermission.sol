// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**
 * @title Interface for the primary 'RegistryPermission' contract for Mantle.
 * @author mantle, Inc.
 * @notice See the `RegistryPermission` contract itself for implementation details.
 */
interface IRegistryPermission {
    function addOperatorRegisterPermission(address operator) external;
    function addOperatorDeregisterPermission(address operator) external;
    function addDataStoreRollupPermission(address pusher) external;
    function addDelegatorPermission(address delegator) external;

    function changeOperatorRegisterPermission(address operator, bool status) external;
    function changeOperatorDeregisterPermission(address operator, bool status) external;
    function changeDataStoreRollupPermission(address pusher, bool status) external;
    function changeDelegatorPermission(address delegator, bool status) external;

    function getOperatorRegisterPermission(address operator) external view returns (bool);
    function getOperatorDeregisterPermission(address operator) external view returns (bool);
    function getDataStoreRollupPermission(address pusher) external view returns (bool);
    function getDelegatorPermission(address delegator) external view returns (bool);
}