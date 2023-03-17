// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Multicall.sol";

contract DeploymentRegistry is Multicall {

    event SettingsRegistered(bytes32 indexed id);
    event Registered(address indexed target, DeploymentInfo info, address indexed sender);
    event Initialized(address indexed target, bytes32 settings);
    event Configured(address indexed target, bytes32 settings);
    event TransferredOwnership(address indexed target, address indexed newOwner);

    struct DeploymentInfo {
        bool initialized;
        uint64 block;
        uint64 timestamp;
        address owner;
        bytes32 hash;
        bytes32 lastConfiguredSettings;
        bytes32 constructSettings;
        bytes32 initializeSettings;
    }

    mapping(bytes32 => bytes) public settings;
    mapping(address => DeploymentInfo) public deploymentInfo;

    modifier onlyOwner(address target) {
        require(msg.sender == deploymentInfo[target].owner, 'DeploymentRegistry: NOT_OWNER');
        _;
    }

    function register(address target, DeploymentInfo calldata info) external {
        require(settings[info.constructSettings].length > 0, 'DeploymentRegistry: INVALID_CONSTRUCT_SETTINGS');
        require(!info.initialized || settings[info.initializeSettings].length > 0, 'DeploymentRegistry: INVALID_INITIALIZE_SETTINGS');
        require(info.hash != bytes32(0), 'DeploymentRegistry: INVALID_HASH');
        require(info.block > 0, 'DeploymentRegistry: INVALID_BLOCK');
        require(info.timestamp > 0, 'DeploymentRegistry: INVALID_TIMESTAMP');
        require(info.owner != address(0), 'DeploymentRegistry: INVALID_OWNER');
        require(deploymentInfo[target].hash == 0, 'DeploymentRegistry: ALREADY_REGISTERED');

        deploymentInfo[target] = info;
        emit Registered(target, info, msg.sender);

        if (info.initialized) emit Initialized(target, info.initializeSettings);
        if (info.lastConfiguredSettings != 0) emit Configured(target, info.lastConfiguredSettings);
        emit TransferredOwnership(target, info.owner);
    }

    function registerSettings(bytes calldata currentSettings) external returns (bytes32 id) {
        id = keccak256(currentSettings);
        require(settings[id].length == 0, 'DeploymentRegistry: SETTINGS_EXIST');
        settings[id] = currentSettings;
        emit SettingsRegistered(id);
    }

    function initialized(address target, bytes32 settingsId) external onlyOwner(target) {
        require(settings[settingsId].length > 0, 'DeploymentRegistry: INVALID_INITIALIZE_SETTINGS');
        DeploymentInfo storage info = deploymentInfo[target];

        require(!info.initialized, 'DeploymentRegistry: ALREADY_INITIALIZED');
        info.initializeSettings = settingsId;
        info.initialized = true;

        emit Initialized(target, settingsId);
    }

    function configured(address target, bytes32 settingsId) external onlyOwner(target) {
        require(settings[settingsId].length > 0, 'DeploymentRegistry: INVALID_CONFIGURATION_SETTINGS');
        deploymentInfo[target].lastConfiguredSettings = settingsId;
        emit Configured(target, settingsId);
    }

    function transferOwnership(address target, address newOwner) external onlyOwner(target) {
        require(newOwner != address(0), 'DeploymentRegistry: INVALID_OWNER');
        deploymentInfo[target].owner = newOwner;
        emit TransferredOwnership(target, newOwner);
    }
}