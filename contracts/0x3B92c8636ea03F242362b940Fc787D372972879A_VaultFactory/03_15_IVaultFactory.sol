// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IVaultFactory {
    event CreateVault(uint256 vaultKeyTokenID, address vaultAddress);

    function createVault(uint256 vaultKeyTokenID)
        external
        returns (address vault);

    function vaultOf(uint256 vaultKeyTokenId)
        external
        view
        returns (address vault);

    function initialize(address vaultImplementationContract, address vaultKeyContract)
        external;
        
}