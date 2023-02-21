// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

/**
 *  @title 0x trade wallet used to hold funds and fullfil orders submitted by Pricers
 */
interface IWallet {
	/// @notice Register with 0x an address that is allowed to sign on behalf of this contract
	/// @param signer EOA that is signing RFQ orders
	function registerAllowedOrderSigner(address signer, bool allowed) external;

	/// @notice Add the supplied amounts to the wallet to fullfill order with
	function deposit(address[] calldata tokens, uint256[] calldata amounts) external;

	/// @notice Withdraw assets from the wallet
	function withdraw(address[] calldata tokens, uint256[] calldata amounts) external;
}