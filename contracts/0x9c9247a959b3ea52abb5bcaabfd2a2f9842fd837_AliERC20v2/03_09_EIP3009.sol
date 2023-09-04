// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title EIP-3009: Transfer With Authorization
 *
 * @notice A contract interface that enables transferring of fungible assets via a signed authorization.
 *      See https://eips.ethereum.org/EIPS/eip-3009
 *      See https://eips.ethereum.org/EIPS/eip-3009#specification
 */
interface EIP3009 {
	/**
	 * @dev Fired whenever the nonce gets used (ex.: `transferWithAuthorization`, `receiveWithAuthorization`)
	 *
	 * @param authorizer an address which has used the nonce
	 * @param nonce the nonce used
	 */
	event AuthorizationUsed(address indexed authorizer, bytes32 indexed nonce);

	/**
	 * @dev Fired whenever the nonce gets cancelled (ex.: `cancelAuthorization`)
	 *
	 * @dev Both `AuthorizationUsed` and `AuthorizationCanceled` imply the nonce
	 *      cannot be longer used, the only difference is that `AuthorizationCanceled`
	 *      implies no smart contract state change made (except the nonce marked as cancelled)
	 *
	 * @param authorizer an address which has cancelled the nonce
	 * @param nonce the nonce cancelled
	 */
	event AuthorizationCanceled(address indexed authorizer, bytes32 indexed nonce);

	/**
	 * @notice Returns the state of an authorization, more specifically
	 *      if the specified nonce was already used by the address specified
	 *
	 * @dev Nonces are expected to be client-side randomly generated 32-byte data
	 *      unique to the authorizer's address
	 *
	 * @param authorizer    Authorizer's address
	 * @param nonce         Nonce of the authorization
	 * @return true if the nonce is used
	 */
	function authorizationState(
		address authorizer,
		bytes32 nonce
	) external view returns (bool);

	/**
	 * @notice Execute a transfer with a signed authorization
	 *
	 * @param from          Payer's address (Authorizer)
	 * @param to            Payee's address
	 * @param value         Amount to be transferred
	 * @param validAfter    The time after which this is valid (unix time)
	 * @param validBefore   The time before which this is valid (unix time)
	 * @param nonce         Unique nonce
	 * @param v             v of the signature
	 * @param r             r of the signature
	 * @param s             s of the signature
	 */
	function transferWithAuthorization(
		address from,
		address to,
		uint256 value,
		uint256 validAfter,
		uint256 validBefore,
		bytes32 nonce,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;

	/**
	 * @notice Receive a transfer with a signed authorization from the payer
	 *
	 * @dev This has an additional check to ensure that the payee's address matches
	 *      the caller of this function to prevent front-running attacks.
	 * @dev See https://eips.ethereum.org/EIPS/eip-3009#security-considerations
	 *
	 * @param from          Payer's address (Authorizer)
	 * @param to            Payee's address
	 * @param value         Amount to be transferred
	 * @param validAfter    The time after which this is valid (unix time)
	 * @param validBefore   The time before which this is valid (unix time)
	 * @param nonce         Unique nonce
	 * @param v             v of the signature
	 * @param r             r of the signature
	 * @param s             s of the signature
	 */
	function receiveWithAuthorization(
		address from,
		address to,
		uint256 value,
		uint256 validAfter,
		uint256 validBefore,
		bytes32 nonce,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;

	/**
	 * @notice Attempt to cancel an authorization
	 *
	 * @param authorizer    Authorizer's address
	 * @param nonce         Nonce of the authorization
	 * @param v             v of the signature
	 * @param r             r of the signature
	 * @param s             s of the signature
	 */
	function cancelAuthorization(
		address authorizer,
		bytes32 nonce,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;
}