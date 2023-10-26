// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title TokenErrors
 * @author Non-Fungible Technologies, Inc.
 *
 * This file contains all custom errors for the token and distribution contracts.
 * All errors are prefixed by  "AT_" for ArcadeToken. Errors located in one place
 * to make it possible to holistically look at all the failure cases.
 */

/**
 * @notice Error thrown when token has already been sent to a specific party.
 */
error AT_AlreadySent();

/**
 * @notice Thrown when a proposed start time for minting is in the past.
 *
 * @param proposedStartTime       The proposed start time for minting.
 * @param currentTime             The current blocks timestamp.
 */
error AT_InvalidMintStart(uint256 proposedStartTime, uint256 currentTime);

/**
 * @notice Thrown when mint function is called prior to the mint start time.
 *
 * @param mintingAllowedAfter     The time when the next mint is allowed.
 * @param currentTime             The current blocks timestamp.
 */
error AT_MintingNotStarted(uint256 mintingAllowedAfter, uint256 currentTime);

/**
 * @notice Thrown when a non-minter address calls setMinter function.
 *
 * @param minter                  The tokens current minter address.
 */
error AT_MinterNotCaller(address minter);

/**
 * @notice Thrown when a zero amount of token is passed to the mint function.
 */
error AT_ZeroMintAmount();

/**
 * @notice Thrown when amount to mint exceeds to annual maximum of 2% the total supply.
 *
 * @param totalSupply             The current total supply of tokens.
 * @param mintCapAmount           The maximum number of tokens that can be minted.
 * @param amount                  The amount of tokens to mint.
 */
error AT_MintingCapExceeded(uint256 totalSupply, uint256 mintCapAmount, uint256 amount);

/**
 * @notice Zero address passed in where not allowed.
 *
 * @param addressType                The name of the parameter for which a zero
 *                                   address was provided.
 */
error AT_ZeroAddress(string addressType);

/**
 * @notice Thrown when the distributor contract already has a token set in state.
 */
error AT_TokenAlreadySet();