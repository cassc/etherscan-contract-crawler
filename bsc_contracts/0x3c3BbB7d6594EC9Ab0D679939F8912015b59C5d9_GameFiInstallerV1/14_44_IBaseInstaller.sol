// SPDX-License-Identifier: BUSL-1.1
// GameFi Core™ by CDEVS

pragma solidity 0.8.10;

import "../type/IEnvTypes.sol";

interface IBaseInstaller is IEnvTypes {
    event CreateEnvironment(
        address indexed sender,
        string name,
        string tag,
        string indexed tagIndexed,
        uint256 environmentId,
        uint256 timestamp
    );

    event CreateInstance(
        address indexed sender,
        uint256 indexed environmentId,
        uint256 instanceType,
        address implementation,
        bytes initializerData,
        uint256 indexed instanceId,
        address instanceContract,
        address instanceProxyAdmin,
        uint256 timestamp
    );

    event UpgradeInstance(
        address indexed sender,
        uint256 indexed environmentId,
        uint256 indexed instanceId,
        address oldImplementation,
        address newImplementation,
        uint256 timestamp
    );

    //
    // General
    //

    function proxyAdmin() external view returns (address);

    //
    // Environments
    //

    function environmentDetails(uint256 environmentId) external view returns (Environment memory);

    function totalEnvironments() external view returns (uint256);

    function environmentOfTagByIndex(string memory tag, uint256 index) external view returns (uint256 environmentId);

    function totalEnvironmentsOfTag(string memory tag) external view returns (uint256);

    //
    // Env instances
    //

    function instanceDetails(uint256 instanceId) external view returns (EnvInstance memory);

    function totalInstances() external view returns (uint256);
}