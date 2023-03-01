// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@arcadexyz/v2-contracts/contracts/interfaces/IVaultFactory.sol";

import "./interfaces/IVaultDepositRouter.sol";
import "./interfaces/IVaultInventoryReporter.sol";

/**
 * @title VaultOwnershipChecker
 * @author Non-Fungible Technologies, Inc.
 *
 * This abstract contract contains utility functions for checking AssetVault
 * ownership or approval, which is needed for many contracts which work with vaults.
 */
abstract contract VaultOwnershipChecker {

    // ============= Errors ==============

    error VOC_ZeroAddress();
    error VOC_InvalidVault(address vault);
    error VOC_NotOwnerOrApproved(address vault, address owner, address caller);

    // ================ Ownership Check ================

    /**
     * @dev Validates that the caller is allowed to deposit to the specified vault (owner or approved),
     *      and that the specified vault exists. Reverts on failed validation.
     *
     * @param factory                       The vault ownership token for the specified vault.
     * @param vault                         The vault that will be deposited to.
     * @param caller                        The caller who wishes to deposit.
     */
    function _checkApproval(address factory, address vault, address caller) internal view {
        if (vault == address(0)) revert VOC_ZeroAddress();
        if (!IVaultFactory(factory).isInstance(vault)) revert VOC_InvalidVault(vault);

        uint256 tokenId = uint256(uint160(vault));
        address owner = IERC721(factory).ownerOf(tokenId);

        if (
            caller != owner
            && IERC721(factory).getApproved(tokenId) != caller
            && !IERC721(factory).isApprovedForAll(owner, caller)
        ) revert VOC_NotOwnerOrApproved(vault, owner, caller);
    }

    /**
     * @dev Validates that the caller is directly the owner of the vault,
     *      and that the specified vault exists. Reverts on failed validation.
     *
     * @param factory                       The vault ownership token for the specified vault.
     * @param vault                         The vault that will be deposited to.
     * @param caller                        The caller who wishes to deposit.
     */
    function _checkOwnership(address factory, address vault, address caller) public view {
        if (vault == address(0)) revert VOC_ZeroAddress();
        if (!IVaultFactory(factory).isInstance(vault)) revert VOC_InvalidVault(vault);

        uint256 tokenId = uint256(uint160(vault));
        address owner = IERC721(factory).ownerOf(tokenId);

        if (caller != owner) revert VOC_NotOwnerOrApproved(vault, owner, caller);
    }
}