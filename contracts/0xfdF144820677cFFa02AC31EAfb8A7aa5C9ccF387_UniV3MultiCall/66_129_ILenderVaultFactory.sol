// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface ILenderVaultFactory {
    event NewVaultCreated(
        address indexed newLenderVaultAddr,
        address vaultOwner,
        uint256 numRegisteredVaults
    );

    /**
     * @notice function creates new lender vaults
     * @param salt salt used for deterministic cloning
     * @return newLenderVaultAddr address of created vault
     */
    function createVault(
        bytes32 salt
    ) external returns (address newLenderVaultAddr);

    /**
     * @notice function returns address registry
     * @return address of registry
     */
    function addressRegistry() external view returns (address);

    /**
     * @notice function returns address of lender vault implementation contract
     * @return address of lender vault implementation
     */
    function lenderVaultImpl() external view returns (address);
}