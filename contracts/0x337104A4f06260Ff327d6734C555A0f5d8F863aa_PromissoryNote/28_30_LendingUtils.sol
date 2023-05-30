// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "../libraries/LoanLibrary.sol";

/**
 * @title LendingUtilsErrors
 * @author Non-Fungible Technologies, Inc.
 *
 * This file contains custom errors for utilities used by the lending protocol contracts.
 * Errors are prefixed by the contract that throws them (e.g., "LC_" for LoanCore).
 */

// ==================================== ERC721 Permit ======================================
/// @notice All errors prefixed with ERC721P_, to separate from other contracts in the protocol.

/**
 * @notice Deadline for the permit has expired.
 *
 * @param deadline                      Permit deadline parameter as a timestamp.
 */
error ERC721P_DeadlineExpired(uint256 deadline);

/**
 * @notice Address of the owner to also be the owner of the tokenId.
 *
 * @param owner                        Owner parameter for the function call.
 */
error ERC721P_NotTokenOwner(address owner);

/**
 * @notice Invalid signature.
 *
 * @param signer                        Signer recovered from ECDSA sugnature hash.
 */
error ERC721P_InvalidSignature(address signer);