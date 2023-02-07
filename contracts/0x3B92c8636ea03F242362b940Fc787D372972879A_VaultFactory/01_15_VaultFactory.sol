// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "@openzeppelin/contracts/proxy/Clones.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./IVault.sol";
import "./IVaultFactory.sol";

/**
 * @title VaultFactory
 * @author Apymon
 *
 * The VaultFactory is responsible for creating and keeping track of Vault instances.
 * It is immutably tied to a ERC721 contract and allows a single Vault to be created
 * for each token.
 *
 **/

contract VaultFactory is IVaultFactory, UUPSUpgradeable, OwnableUpgradeable {
    address public VAULT_IMPLEMENTATION_CONTRACT;
    address public VAULT_KEY_CONTRACT;

    mapping(uint256 => address) internal vaults;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     *
     * @notice Initializes the Vault instance and ties it to a particular ERC721 token, referred to as the key.
     * @dev Cannot be called on the implementation contract and can only be called once per proxy instance.
     *
     * @param vaultImplementationContract		The address of the vault implementation contract that will be used to create vault instances.
     * @param vaultKeyContract					The vault key contract that will act
     *
     **/

    function initialize(
        address vaultImplementationContract,
        address vaultKeyContract
    ) external override initializer {
        __Ownable_init();
        VAULT_IMPLEMENTATION_CONTRACT = vaultImplementationContract;
        VAULT_KEY_CONTRACT = vaultKeyContract;
    }

    /**
     *
     * @notice Creates a vault instance that is owned by a given token id from the vault key contract, can only be called by the token id owner and once per token id.
     *
     * @param vaultKeyTokenId       			The id of the token that will act as the key to the vault.
     *
     **/

    function createVault(uint256 vaultKeyTokenId)
        external
        returns (address vault)
    {
        require(
            vaults[vaultKeyTokenId] == address(0),
            "Vault key is already associated with a vault."
        );

        require(
            msg.sender == IERC721(VAULT_KEY_CONTRACT).ownerOf(vaultKeyTokenId),
            "Caller does not own the provided vault key."
        );

        vault = _createVault(vaultKeyTokenId);
        vaults[vaultKeyTokenId] = vault;

        emit CreateVault(vaultKeyTokenId, vault);

        return vault;
    }

    /**
     *
     * @notice Returns the address of the vault associated with a given key token id
     *
     * @param vaultKeyTokenId       			The token id of the key.
     * @return vault                			The address of the vault.
     *
     **/

    function vaultOf(uint256 vaultKeyTokenId)
        external
        view
        returns (address vault)
    {
        return vaults[vaultKeyTokenId];
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function _createVault(uint256 vaultKeyTokenId)
        internal
        returns (address vault)
    {
        vault = Clones.clone(VAULT_IMPLEMENTATION_CONTRACT);
        IVault(vault).initialize(VAULT_KEY_CONTRACT, vaultKeyTokenId);

        return address(vault);
    }
}