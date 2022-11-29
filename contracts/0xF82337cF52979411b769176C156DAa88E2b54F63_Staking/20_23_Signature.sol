// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

/// @notice Denotes the type of signature being submitted to contracts that support multiple
enum SignatureType {
	INVALID,
	// Specifically signTypedData_v4
	EIP712,
	// Specifically personal_sign
	ETHSIGN
}