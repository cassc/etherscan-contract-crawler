//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

interface IProviderRegistry {
    event ProviderChanged(bytes4 indexed id, address provider);

    function setProvider(bytes4 id, address provider) external;

    function setProviders(bytes4[] calldata ids, address[] calldata providers) external;

    function removeProvider(bytes4 id) external;

    function removeProviders(bytes4[] calldata ids) external;

    function getProvider(bytes4 id) external view returns (address provider);

    function getProviders() external view returns (bytes4[] memory ids, address[] memory providers);
}