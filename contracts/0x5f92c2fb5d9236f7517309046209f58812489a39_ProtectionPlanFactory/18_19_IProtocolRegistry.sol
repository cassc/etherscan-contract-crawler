// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IProtocolRegistry {
    function getAddress(bytes32 _contractName) external view returns (address);

    function getRelayerAddress() external view returns (address);

    function getVaultAddress() external view returns (address);

    function getUpgradeableAddress() external view returns (address);

    function getSignerAddress() external view returns (address);

    function setVaultAddress(address _contractLocation) external returns (address);

    function setRelayerAddress(address _contractLocation) external returns (address);

    function setUpgradeableAddress(address _contractLocation) external returns (address);

    function setSignerAddress(address _signerAddress) external returns (address);
}