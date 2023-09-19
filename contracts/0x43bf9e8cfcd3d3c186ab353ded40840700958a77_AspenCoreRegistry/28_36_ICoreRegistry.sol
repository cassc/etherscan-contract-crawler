// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

interface ICoreRegistryV0 {
    function getConfig(string calldata _version) external view returns (address);

    function setConfigContract(address configContract, string calldata _version) external;

    function getDeployer(string calldata _version) external view returns (address);

    function setDeployerContract(address _deployerContract, string calldata _version) external;

    event DeployerContractAdded(string contractName, address contractAddress);

    event ContractAdded(bytes32 namehash, address _address);

    event ContractForStringAdded(string name, address _address);

    event ConfigContractAdded(string configVersionedName, address contractAddress);
}