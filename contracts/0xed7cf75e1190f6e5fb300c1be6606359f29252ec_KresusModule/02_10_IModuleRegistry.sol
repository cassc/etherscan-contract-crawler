// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title IModuleRegistry
 * @notice Interface for the registry of authorised modules.
 */
interface IModuleRegistry {
    function registerModule(address _module, bytes32 _name) external;

    function deregisterModule(address _module) external;

    function registerUpgrader(address _upgrader, bytes32 _name) external;

    function deregisterUpgrader(address _upgrader) external;

    function recoverToken(address _token) external;

    function moduleInfo(address _module) external view returns (bytes32);

    function upgraderInfo(address _upgrader) external view returns (bytes32);

    function isRegisteredModule(address _module) external view returns (bool);

    function isRegisteredModule(address[] calldata _modules) external view returns (bool);

    function isRegisteredUpgrader(address _upgrader) external view returns (bool);
}