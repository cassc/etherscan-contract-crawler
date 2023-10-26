// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

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
 * @notice CanCallOn authorization returned false.
 *
 * @param caller                             Msg.sender of the function call.
 */
error AV_MissingAuthorization(address caller);

/**
 * @notice Call disallowed.
 *
 * @param to                                The contract address to call.
 * @param data                              The data to call the contract with.
 */
error AV_NonWhitelistedCall(address to, bytes4 data);

/**
 * @notice Approval disallowed.
 *
 * @param token                             The token to approve.
 * @param spender                           The spender to approve.
 */
error AV_NonWhitelistedApproval(address token, address spender);

/**
 * @notice Cannot withdraw more than 25 items from a vault at a time.
 *
 * @param arrayLength                  Total elements provided.
 */
error AV_TooManyItems(uint256 arrayLength);

/**
 * @notice The length of either the tokenIds or tokenTypes array does not match
 *         the length of the tokenAddress array.
 *
 * @param arrayType                    Array type that does not match tokenAddress array length.
 */
error AV_LengthMismatch(string arrayType);

/**
 * @notice Zero address passed in where not allowed.
 *
 * @param addressType                  The name of the parameter for which a zero address was provided.
 */
error AV_ZeroAddress(string addressType);

/**
 * @notice Delegation disallowed.
 *
 * @param token                             The token to delegate.
 */
error AV_NonWhitelistedDelegation(address token);

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
 * @notice Zero address passed in where not allowed.
 *
 * @param addressType                  The name of the parameter for which a zero address was provided.
 */
error VF_ZeroAddress(string addressType);

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

/**
 * @notice Not enough msg.value sent for the required mint fee.
 *
 * @param value                              The msg.value.
 * @param requiredMintFee                    The required mint fee.
 */
error VF_InsufficientMintFee(uint256 value, uint256 requiredMintFee);

/**
 * @notice Non-existant token id provided as argument.
 *
 * @param tokenId                       The ID of the token to lookup the URI for.
 */
error VF_DoesNotExist(uint256 tokenId);

// ================================== Call Whitelist ======================================
/// @notice All errors prefixed with CW_, to separate from other contracts in the protocol.

/**
 * @notice Cannot whitelist a call which has already been whitelisted.
 *
 * @param callee                             The contract to be added to CallWhitelist mapping.
 * @param selector                           The function selector to be added to CallWhitelist mapping.
 */
error CW_AlreadyWhitelisted(address callee, bytes4 selector);

/**
 * @notice Cannot remove a call from the CallWhitelist that has not yet been added.
 *
 * @param callee                             The contract to be removed from CallWhitelist mapping.
 * @param selector                           The function selector to be removed from CallWhitelist mapping.
 */
error CW_NotWhitelisted(address callee, bytes4 selector);

// ================================== Call Whitelist Delegation ======================================

/**
 * @notice Zero address passed in the constructor.
 */
error CWD_ZeroAddress();

/**
 * @notice The registry address provided is currently set as the registry.
 */
error CWD_RegistryAlreadySet();