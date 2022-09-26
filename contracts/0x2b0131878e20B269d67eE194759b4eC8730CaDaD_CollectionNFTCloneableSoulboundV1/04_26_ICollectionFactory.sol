// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface ICollectionFactory {
    function addImplementationAddress(
        bytes32 _hashedEcosystemName,
        address _implementationAddress,
        bool cloneable
    ) external;

    function createCollection(address _implementationAddress, bytes memory _initializationData) external;

    function setFactoryMaintainerAddress(address _factoryMaintainerAddress) external;

    function removeImplementationAddresses(
        bytes32[] memory _hashedEcosystemNames,
        address[] memory _implementationAddresses,
        uint256[] memory _indexes
    ) external;

    function removeCollection(
        address _implementationAddress,
        address _collectionAddress,
        uint256 _index
    ) external;

    function createEcosystemSettings(string memory _ecosystemName, bytes memory _settings) external;

    function updateEcosystemSettings(bytes32 _hashedEcosystemName, bytes memory _settings) external;

    function getEcosystemSettings(bytes32 _hashedEcosystemName, uint64 _blockNumber)
        external
        view
        returns (bytes memory);

    function getEcosystems() external view returns (bytes32[] memory);

    function getEcosystems(uint256 _start, uint256 _end) external view returns (bytes32[] memory);

    function getCollections(address _implementationAddress) external view returns (address[] memory);

    function getCollections(
        address _implementationAddress,
        uint256 _start,
        uint256 _end
    ) external view returns (address[] memory);

    function getImplementationAddresses(bytes32 _hashedEcosystemName) external view returns (address[] memory);

    function getImplementationAddresses(
        bytes32 _hashedEcosystemName,
        uint256 _start,
        uint256 _end
    ) external view returns (address[] memory);
}