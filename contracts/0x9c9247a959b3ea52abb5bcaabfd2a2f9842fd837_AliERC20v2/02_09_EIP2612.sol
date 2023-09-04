// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title EIP-2612: permit - 712-signed approvals
 *
 * @notice A function permit extending ERC-20 which allows for approvals to be made via secp256k1 signatures.
 *      This kind of “account abstraction for ERC-20” brings about two main benefits:
 *        - transactions involving ERC-20 operations can be paid using the token itself rather than ETH,
 *        - approve and pull operations can happen in a single transaction instead of two consecutive transactions,
 *        - while adding as little as possible over the existing ERC-20 standard.
 *
 * @notice See https://eips.ethereum.org/EIPS/eip-2612#specification
 */
interface EIP2612 {
	/**
	 * @notice EIP712 domain separator of the smart contract. It should be unique to the contract
	 *      and chain to prevent replay attacks from other domains, and satisfy the requirements of EIP-712,
	 *      but is otherwise unconstrained.
	 */
	function DOMAIN_SEPARATOR() external view returns (bytes32);

	/**
	 * @notice Counter of the nonces used for the given address; nonce are used sequentially
	 *
	 * @dev To prevent from replay attacks nonce is incremented for each address after a successful `permit` execution
	 *
	 * @param owner an address to query number of used nonces for
	 * @return number of used nonce, nonce number to be used next
	 */
	function nonces(address owner) external view returns (uint);

	/**
	 * @notice For all addresses owner, spender, uint256s value, deadline and nonce, uint8 v, bytes32 r and s,
	 *      a call to permit(owner, spender, value, deadline, v, r, s) will set approval[owner][spender] to value,
	 *      increment nonces[owner] by 1, and emit a corresponding Approval event,
	 *      if and only if the following conditions are met:
	 *        - The current blocktime is less than or equal to deadline.
	 *        - owner is not the zero address.
	 *        - nonces[owner] (before the state update) is equal to nonce.
	 *        - r, s and v is a valid secp256k1 signature from owner of the message:
	 *
	 * @param owner token owner address, granting an approval to spend its tokens
	 * @param spender an address approved by the owner (token owner)
	 *      to spend some tokens on its behalf
	 * @param value an amount of tokens spender `spender` is allowed to
	 *      transfer on behalf of the token owner
	 * @param v the recovery byte of the signature
	 * @param r half of the ECDSA signature pair
	 * @param s half of the ECDSA signature pair
	 */
	function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}