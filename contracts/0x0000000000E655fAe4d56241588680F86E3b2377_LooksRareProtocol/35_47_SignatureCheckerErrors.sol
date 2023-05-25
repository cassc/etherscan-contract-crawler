// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @notice It is emitted if the signer is null.
 */
error NullSignerAddress();

/**
 * @notice It is emitted if the signature is invalid for an EOA (the address recovered is not the expected one).
 */
error SignatureEOAInvalid();

/**
 * @notice It is emitted if the signature is invalid for a ERC1271 contract signer.
 */
error SignatureERC1271Invalid();

/**
 * @notice It is emitted if the signature's length is neither 64 nor 65 bytes.
 */
error SignatureLengthInvalid(uint256 length);

/**
 * @notice It is emitted if the signature is invalid due to S parameter.
 */
error SignatureParameterSInvalid();

/**
 * @notice It is emitted if the signature is invalid due to V parameter.
 */
error SignatureParameterVInvalid(uint8 v);