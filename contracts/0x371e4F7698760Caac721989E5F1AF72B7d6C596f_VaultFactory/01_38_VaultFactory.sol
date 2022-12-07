// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import "../interfaces/IAssetVault.sol";
import "../interfaces/IVaultFactory.sol";
import "../ERC721PermitUpgradeable.sol";

import { VF_InvalidTemplate, VF_TokenIdOutOfBounds, VF_NoTransferWithdrawEnabled } from "../errors/Vault.sol";

/**
 * @title VaultFactory
 * @author Non-Fungible Technologies, Inc.
 *
 * The Vault factory is used for creating and registering AssetVault contracts, which
 * is also an ERC721 that maps "ownership" of its tokens to ownership of created
 * vault assets (see OwnableERC721).
 *
 * Each Asset Vault is created via "intializeBundle", and uses a specified template
 * and the OpenZeppelin Clones library to cheaply deploy a new clone pointing to logic
 * in the template. The address the newly created vault is deployed to is converted
 * into a uint256, which ends up being the token ID minted.
 *
 * Using OwnableERC721, created Asset Vaults then map their own address back into
 * a uint256, and check the ownership of the token ID matching that uint256 within the
 * VaultFactory in order to determine their own contract owner. The VaultFactory contains
 * conveniences to allow switching between the address and uint256 formats.
 */
contract VaultFactory is ERC721EnumerableUpgradeable, ERC721PermitUpgradeable, IVaultFactory {
    // ============================================ STATE ==============================================

    /// @dev The template contract for asset vaults.
    address public template;
    /// @dev The CallWhitelist contract definining the calling restrictions for vaults.
    address public whitelist;

    // ========================================== CONSTRUCTOR ===========================================

    /**
     * @notice Runs the initializer function in an upgradeable contract.
     *
     * @dev Added unsafe-allow comment to notify upgrades plugin to accept the constructor.
     */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    // ========================================== INITIALIZER ===========================================

    function initialize(address _template, address _whitelist) public initializer {
        __ERC721_init("Asset Vault", "AV");
        __ERC721PermitUpgradeable_init("Asset Vault");
        __ERC721Enumerable_init_unchained();

        if (_template == address(0)) revert VF_InvalidTemplate(_template);
        template = _template;
        whitelist = _whitelist;
    }

    // ===================================== UPGRADE AUTHORIZATION ======================================

    /**
     * @notice Authorization function to define who should be allowed to upgrade the contract.
     *
     * @param newImplementation     The address of the upgraded version of this contract.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(ADMIN_ROLE) {}

    /**
     * @notice Check if the given address is a vault instance created by this factory.
     *
     * @param instance              The address to check.
     *
     * @return validity             Whether the address is a valid vault instance.
     */
    function isInstance(address instance) external view override returns (bool validity) {
        return _exists(uint256(uint160(instance)));
    }

    /**
     * @notice Return the number of instances created by this factory.
     *         Also the total supply of ERC721 bundle tokens.
     *
     * @return count                The total number of instances.
     */
    function instanceCount() external view override returns (uint256 count) {
        return totalSupply();
    }

    /**
     * @notice Return the address of the instance for the given token ID.
     *
     * @param tokenId               The token ID for which to find the instance.
     *
     * @return instance             The address of the derived instance.
     */
    function instanceAt(uint256 tokenId) external view override returns (address instance) {
        // check _owners[tokenId] != address(0)
        if (!_exists(tokenId)) revert VF_TokenIdOutOfBounds(tokenId);

        return address(uint160(tokenId));
    }

    /**
     * @notice Return the address of the instance for the given index. Allows
     *         for enumeration over all instances.
     *
     * @param index                 The index for which to find the instance.
     *
     * @return instance             The address of the instance, derived from the corresponding
     *                              token ID at the specified index.
     */
    function instanceAtIndex(uint256 index) external view override returns (address instance) {
        return address(uint160(tokenByIndex(index)));
    }

    // ==================================== FACTORY OPERATIONS ==========================================

    /**
     * @notice Creates a new bundle token and vault contract for `to`. Its token ID will be
     * automatically assigned (and available on the emitted {IERC721-Transfer} event)
     *
     * See {ERC721-_mint}.
     *
     * @param to                    The address that will own the new vault.
     *
     * @return tokenID              The token ID of the bundle token, derived from the vault address.
     */
    function initializeBundle(address to) external override returns (uint256) {
        address vault = _create();

        _mint(to, uint256(uint160(vault)));

        emit VaultCreated(vault, to);
        return uint256(uint160(vault));
    }

    /**
     * @dev Creates and initializes a minimal proxy vault instance,
     *      using the OpenZeppelin Clones library.
     *
     * @return vault                The address of the newly created vault.
     */
    function _create() internal returns (address vault) {
        vault = Clones.clone(template);
        IAssetVault(vault).initialize(whitelist);
        return vault;
    }

    // ===================================== ERC721 UTILITIES ===========================================

    /**
     * @dev Hook that is called before any token transfer.
     * @dev This notifies the vault contract about the ownership transfer.
     *
     * @dev Does not let tokens with withdraw enabled be transferred, which ensures
     *      that items cannot be withdrawn in a frontrunning attack before loan origination.
     *
     * @param from                  The previous owner of the token.
     * @param to                    The owner of the token after transfer.
     * @param tokenId               The token ID.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        IAssetVault vault = IAssetVault(address(uint160(tokenId)));
        if (vault.withdrawEnabled()) revert VF_NoTransferWithdrawEnabled(tokenId);

        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721PermitUpgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}