// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import {
	ReentrancyGuard
} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./core/Executor.sol";

/// Thrown if the count of items in required argument arrays differ.
error ArgumentsLengthMismatched ();

/**
	Thrown during mass-cancelation if the provided nonce is lower than current 
	nonce.

	@param nonce The nonce used to indicate the current set of uncanceled user 
		orders.
*/
error NonceLowerThanCurrent (
	uint256 nonce
);

/// Thrown if attempting to send items to the zero address.
error InvalidRecipient ();

/**
	Thrown if attempting to execute an order that is not valid for fulfillment; 
	this prevents offers from being executed as if they were listings.
*/
error WrongOrderType ();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title GigaMart Exchange
	@author Rostislav Khlebnikov <@catpic5buck>
	@custom:contributor Tim Clancy <@_Enoch>
	@custom:contributor throw; <@0xthrpw>
	
	GigaMart is a new NFT platform built for the world by the SuperVerse DAO. 
	This is the first iteration of the exchange and is based on a delegated user 
	proxy architecture.

	@custom:date December 4th, 2022.
*/
contract GigaMart is Executor, ReentrancyGuard {

	/**
		Emitted when a user cancels all of their orders. All orders with a nonce 
		less than `minNonce` will be canceled.

		@param sender The caller who is canceling their orders.
		@param minNonce The new nonce to use in mass-cancelation.
	*/
	event AllOrdersCancelled (
		address indexed sender,
		uint256 minNonce
	);

	/**
		Construct a new instance of the GigaMart exchange.

		@param _registry The address of the existing proxy registry.
		@param _tokenTransferProxy The address of the token transfer proxy contract.
		@param _validator The address of a privileged validator for permitting 
			collection administrators to control their royalty fees.
		@param _protocolFeeRecipient The address which receives fees from the 
			exchange.
		@param _protocolFeePercent The percent of fees taken by 
			`_protocolFeeRecipient` in basis points (1/100th %; i.e. 200 = 2%).
	*/
	constructor (
		IProxyRegistry _registry,
		TokenTransferProxy _tokenTransferProxy,
		address _validator,
		address _protocolFeeRecipient,
		uint96 _protocolFeePercent
	) Executor(
		_registry,
		_tokenTransferProxy,
		_validator,
		_protocolFeeRecipient,
		_protocolFeePercent
	) { }

	/**
		Allow the caller to cancel an order so long as they are the maker of the 
		order.

		@param _order The `Order` data to cancel.
	*/
	function cancelOrder (
		Entities.Order calldata _order
	) external {
		_cancelOrder(_order);
	}

	/**
		Allow the caller to cancel a set of particular orders so long as they are 
		the maker of each order.

		@param _orders An array of `Order` data to cancel.
	*/
	function cancelOrders (
		Entities.Order[] calldata _orders
	) public {
		for (uint256 i; i < _orders.length; ) {
			_cancelOrder(_orders[i]);
			unchecked {
				++i;
			}
		}
	}

	/**
		Allow the caller to cancel all of their orders created with a nonce lower 
		than the new `_minNonce`.

		@param _minNonce The new nonce to use in mass-cancelation.

		@custom:throws NonceLowerThanCurrent if the provided nonce is not less than 
			the current nonce.
	*/
	function cancelAllOrders (
		uint256 _minNonce
	) external {

		// Verify that the new nonce is not less than the current nonce.
		if (_minNonce < minOrderNonces[msg.sender]) {
			revert NonceLowerThanCurrent(minOrderNonces[msg.sender]);
		}

		// Set the new minimum nonce and emit an event.
		minOrderNonces[msg.sender] = _minNonce;
		emit AllOrdersCancelled(msg.sender, _minNonce);
	}

	/**
		Transfer multiple items using the user-proxy and executable bytecode.

		@param _targets The array of addresses which should be called with the 
			function calls encoded in `_data`.
		@param _data The array of encoded function calls performed against the 
			addresses in `_targets`.

		@custom:throws ArgumentsLengthMismatched if the `_targets` and `_data` 
			arrays are mismatched.
	*/
	function transferMultipleItems (
		address[] calldata _targets,
		bytes[] calldata _data
	) external {
		if (_targets.length != _data.length) {
			revert ArgumentsLengthMismatched();
		}
		_multiTransfer(_targets, _data);
	}

	/**
		Exchange a single ERC-721 or ERC-1155 item for Ether or ERC-20 tokens.

		@param _recipient The address which will receive the item.
		@param _order The `Order` to execute.
		@param _signature The signature provided for fulfilling the order.
		@param _tokenId The unique token ID of the item.
		@param _toInvalidate An optional array of `Order`s by the same caller to 
			cancel while fulfilling the exchange.

		@custom:throws InvalidRecipient if the item `_recipient` is the zero 
			address.
	*/
	function exchangeSingleItem (
		address _recipient,
		Entities.Order memory _order,
		Entities.Sig calldata _signature,
		uint256 _tokenId,
		Entities.Order[] calldata _toInvalidate
	) external payable nonReentrant {

		// Prevent the item from being sent to the zero address.
		if (_recipient == address(0)) {
			revert InvalidRecipient();
		}

		// Perform the exchange.
		_exchange(_recipient, _order, _signature, _tokenId);
		
		// Optionally invalidate other orders while performing this exchange.
		if (_toInvalidate.length > 0) {
			cancelOrders(_toInvalidate);
		}
	}

	/**
		Exchange multiple ERC-721 or ERC-1155 items for Ether or ERC-20 tokens.

		@param _recipient The address which will receive the items.
		@param _orders The array of orders that are being executed.
		@param _signatures The array of signatures provided for fulfilling the 
			orders.
		@param _toInvalidate An optional array of `Order`s by the same caller to 
			cancel while fulfilling the exchange.

		@custom:throws ArgumentsLengthMismatched if the `_orders` and `_signatures` 
			arrays are mismatched.
		@custom:throws InvalidRecipient if the item `_recipient` is the zero 
			address.
		@custom:throws WrongOrderType if attempting to fulfill an offer using this 
			function.
	*/
	function exchangeMultipleItems (
		address _recipient,
		Entities.Order[] memory _orders,
		Entities.Sig[] calldata _signatures,
		Entities.Order[] calldata _toInvalidate
	) external payable nonReentrant {
		if (_orders.length != _signatures.length) {
			revert ArgumentsLengthMismatched();
		}

		// Prevent the item from being sent to the zero address.
		if (_recipient == address(0)) {
			revert InvalidRecipient();
		}

		// Prepare an accumulator array for collecting payments.
		bytes memory payments = new bytes(32);
		for (uint256 i; i < _orders.length; ) {

			// Prevent offers from being fulfilled by this function.
			if (uint8(_orders[i].outline.saleKind) > 2) {
				revert WrongOrderType();
			}

			// Perform each exchange and accumulate payments.
			_exchangeUnchecked(_recipient, _orders[i], _signatures[i], payments);
			unchecked {
				i++;
			}
		}

		// Fulfill the accumulated payment.
		_pay(payments, msg.sender, address(tokenTransferProxy));

		// Optionally invalidate other orders after performing this exchange.
		if (_toInvalidate.length > 0) {
			cancelOrders(_toInvalidate);
		}
	}
}