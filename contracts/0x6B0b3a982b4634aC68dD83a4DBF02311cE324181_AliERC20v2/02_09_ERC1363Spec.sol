// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC20Spec.sol";
import "./ERC165Spec.sol";

/**
 * @title ERC1363 Interface
 *
 * @dev Interface defining a ERC1363 Payable Token contract.
 *      Implementing contracts MUST implement the ERC1363 interface as well as the ERC20 and ERC165 interfaces.
 */
interface ERC1363 is ERC20, ERC165  {
	/*
	 * Note: the ERC-165 identifier for this interface is 0xb0202a11.
	 * 0xb0202a11 ===
	 *   bytes4(keccak256('transferAndCall(address,uint256)')) ^
	 *   bytes4(keccak256('transferAndCall(address,uint256,bytes)')) ^
	 *   bytes4(keccak256('transferFromAndCall(address,address,uint256)')) ^
	 *   bytes4(keccak256('transferFromAndCall(address,address,uint256,bytes)')) ^
	 *   bytes4(keccak256('approveAndCall(address,uint256)')) ^
	 *   bytes4(keccak256('approveAndCall(address,uint256,bytes)'))
	 */

	/**
	 * @notice Transfer tokens from `msg.sender` to another address and then call `onTransferReceived` on receiver
	 * @param to address The address which you want to transfer to
	 * @param value uint256 The amount of tokens to be transferred
	 * @return true unless throwing
	 */
	function transferAndCall(address to, uint256 value) external returns (bool);

	/**
	 * @notice Transfer tokens from `msg.sender` to another address and then call `onTransferReceived` on receiver
	 * @param to address The address which you want to transfer to
	 * @param value uint256 The amount of tokens to be transferred
	 * @param data bytes Additional data with no specified format, sent in call to `to`
	 * @return true unless throwing
	 */
	function transferAndCall(address to, uint256 value, bytes memory data) external returns (bool);

	/**
	 * @notice Transfer tokens from one address to another and then call `onTransferReceived` on receiver
	 * @param from address The address which you want to send tokens from
	 * @param to address The address which you want to transfer to
	 * @param value uint256 The amount of tokens to be transferred
	 * @return true unless throwing
	 */
	function transferFromAndCall(address from, address to, uint256 value) external returns (bool);


	/**
	 * @notice Transfer tokens from one address to another and then call `onTransferReceived` on receiver
	 * @param from address The address which you want to send tokens from
	 * @param to address The address which you want to transfer to
	 * @param value uint256 The amount of tokens to be transferred
	 * @param data bytes Additional data with no specified format, sent in call to `to`
	 * @return true unless throwing
	 */
	function transferFromAndCall(address from, address to, uint256 value, bytes memory data) external returns (bool);

	/**
	 * @notice Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
	 * and then call `onApprovalReceived` on spender.
	 * @param spender address The address which will spend the funds
	 * @param value uint256 The amount of tokens to be spent
	 */
	function approveAndCall(address spender, uint256 value) external returns (bool);

	/**
	 * @notice Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
	 * and then call `onApprovalReceived` on spender.
	 * @param spender address The address which will spend the funds
	 * @param value uint256 The amount of tokens to be spent
	 * @param data bytes Additional data with no specified format, sent in call to `spender`
	 */
	function approveAndCall(address spender, uint256 value, bytes memory data) external returns (bool);
}

/**
 * @title ERC1363Receiver Interface
 *
 * @dev Interface for any contract that wants to support `transferAndCall` or `transferFromAndCall`
 *      from ERC1363 token contracts.
 */
interface ERC1363Receiver {
	/*
	 * Note: the ERC-165 identifier for this interface is 0x88a7ca5c.
	 * 0x88a7ca5c === bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))
	 */

	/**
	 * @notice Handle the receipt of ERC1363 tokens
	 *
	 * @dev Any ERC1363 smart contract calls this function on the recipient
	 *      after a `transfer` or a `transferFrom`. This function MAY throw to revert and reject the
	 *      transfer. Return of other than the magic value MUST result in the
	 *      transaction being reverted.
	 *      Note: the token contract address is always the message sender.
	 *
	 * @param operator address The address which called `transferAndCall` or `transferFromAndCall` function
	 * @param from address The address which are token transferred from
	 * @param value uint256 The amount of tokens transferred
	 * @param data bytes Additional data with no specified format
	 * @return `bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))`
	 *      unless throwing
	 */
	function onTransferReceived(address operator, address from, uint256 value, bytes memory data) external returns (bytes4);
}

/**
 * @title ERC1363Spender Interface
 *
 * @dev Interface for any contract that wants to support `approveAndCall`
 *      from ERC1363 token contracts.
 */
interface ERC1363Spender {
	/*
	 * Note: the ERC-165 identifier for this interface is 0x7b04a2d0.
	 * 0x7b04a2d0 === bytes4(keccak256("onApprovalReceived(address,uint256,bytes)"))
	 */

	/**
	 * @notice Handle the approval of ERC1363 tokens
	 *
	 * @dev Any ERC1363 smart contract calls this function on the recipient
	 *      after an `approve`. This function MAY throw to revert and reject the
	 *      approval. Return of other than the magic value MUST result in the
	 *      transaction being reverted.
	 *      Note: the token contract address is always the message sender.
	 *
	 * @param owner address The address which called `approveAndCall` function
	 * @param value uint256 The amount of tokens to be spent
	 * @param data bytes Additional data with no specified format
	 * @return `bytes4(keccak256("onApprovalReceived(address,uint256,bytes)"))`
	 *      unless throwing
	 */
	function onApprovalReceived(address owner, uint256 value, bytes memory data) external returns (bytes4);
}