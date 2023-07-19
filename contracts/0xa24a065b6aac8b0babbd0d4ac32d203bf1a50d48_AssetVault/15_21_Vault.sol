// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

/**
 * @title VaultErrors
 * @author Non-Fungible Technologies, Inc.
 *
 * This file contains all custom errors for vault contracts used by the protocol.
 * All errors prefixed by the contract that throws them (e.g., "AV_" for Asset Vault).
 * Errors located in one place to make it possible to holistically look at all
 * asset vault failure cases.
 */

// ==================================== Asset Vault ======================================
/// @notice All errors prefixed with AV_, to separate from other contracts in the protocol.

/**
 * @notice Vault withdraws must be enabled.
 */
error AV_WithdrawsDisabled();

/**
 * @notice Vault withdraws enabled.
 */
error AV_WithdrawsEnabled();

/**
 * @notice Asset vault already initialized.
 *
 * @param ownershipToken                    Caller of initialize function in asset vault contract.
 */
error AV_AlreadyInitialized(address ownershipToken);

/**
 * @notice Call disallowed.
 *
 * @param caller                             Msg.sender of the function call.
 */
error AV_CallDisallowed(address caller);

/**
 * @notice Call disallowed.
 *
 * @param to                                The contract address to call.
 * @param data                              The data to call the contract with.
 */
error AV_NonWhitelistedCall(address to, bytes4 data);

// ==================================== Ownable ERC721 ======================================
/// @notice All errors prefixed with OERC721_, to separate from other contracts in the protocol.

/**
 * @notice Function caller is not the owner.
 *
 * @param caller                             Msg.sender of the function call.
 */
error OERC721_CallerNotOwner(address caller);

// ==================================== Vault Factory ======================================
/// @notice All errors prefixed with VF_, to separate from other contracts in the protocol.

/**
 * @notice Template contract is invalid.
 *
 * @param template                           Template contract to be cloned.
 */
error VF_InvalidTemplate(address template);

/**
 * @notice Global index out of bounds.
 *
 * @param tokenId                            AW-V2 tokenId of the asset vault.
 */
error VF_TokenIdOutOfBounds(uint256 tokenId);

/**
 * @notice Cannot transfer with withdraw enabled.
 *
 * @param tokenId                            AW-V2 tokenId of the asset vault.
 */
error VF_NoTransferWithdrawEnabled(uint256 tokenId);