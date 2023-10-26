// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title ReputationBadgeErrors
 * @author Non-Fungible Technologies, Inc.
 *
 * This file contains all custom errors for the Reputation Badge NFT contract.
 * All errors are prefixed by  "RB_" for ReputationBadge. Errors located in one place
 * to make it possible to holistically look at all the failure cases.
 */

/**
 * @notice Thrown when the merkle proof provided does not validate the user's claim.
 */
error RB_InvalidMerkleProof();

/**
 * @notice Thrown when ETH amount sent to mint is insufficient.
 *
 * @param mintPrice              The price to mint the badge.
 * @param amountSent             The amount of ETH sent to mint the badge.
 */
error RB_InvalidMintFee(uint256 mintPrice, uint256 amountSent);

/**
 * @notice Thrown when the amount to claim is greater than recipients total claimable amount.
 *
 * @param amountToClaim          The amount to claim.
 * @param totalClaimableAmount   The total amount entitled to claim.
 */
error RB_InvalidClaimAmount(uint256 amountToClaim, uint256 totalClaimableAmount);

/**
 * @notice Zero address passed in where not allowed.
 *
 * @param addressType                The name of the parameter for which a zero
 *                                   address was provided.
 */
error RB_ZeroAddress(string addressType);

/**
 * @notice Thrown when the claim expiration has passed for a specific merkle root.
 *
 * @param claimExpiration        The expiration date for the claim.
 * @param currentTimestamp       The current timestamp.
 */
error RB_ClaimingExpired(uint48 claimExpiration, uint48 currentTimestamp);

/**
 * @notice Thrown when the claim data array is empty.
 */
error RB_NoClaimData();

/**
 * @notice Thrown when the array is larger than 50 elements.
 */
error RB_ArrayTooLarge();

/**
 * @notice Thrown when two array lengths do not match.
 */
error RB_ArrayMismatch();

/**
 * @notice Thrown when the claim expiration is invalid when publishing data.
 *
 * @param timeSent              The passed to function.
 * @param currentTime           The current timestamp.
 */
error RB_InvalidExpiration(uint256 timeSent, uint256 currentTime);

/**
 * @notice Thrown when user tries to mint tokenId of zero. Token ID zero is excluded
 *         from receiving a multiplier in the NFTBoostVault.
 */
error RB_ZeroTokenId();

/**
 * @notice Thrown when user passes zero as the amount to mint function.
 */
error RB_ZeroClaimAmount();