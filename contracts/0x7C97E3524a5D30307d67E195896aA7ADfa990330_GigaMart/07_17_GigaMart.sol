// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {
	ReentrancyGuard
} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {
	IAssetHandler,
	NativeTransfer,
	Marketplace
} from "./lib/Marketplace.sol";

import {
	Order,
	Execution,
	Fulfillment
} from "./lib/Order.sol";

/// Thrown if recipient address is not specified.
error InvalidRecipient ();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title GigaMart Exchange
	@author Rostislav Khlebnikov <@catpic5buck>
	@custom:contributor Tim Clancy <@_Enoch>
	@custom:contributor throw; <@0xthrpw>
	
	GigaMart is a new NFT platform built for the world by the SuperVerse DAO. 
	@custom:date March 17th, 2023.
*/
contract GigaMart is ReentrancyGuard, Marketplace {
	using NativeTransfer for address;

	/**
		Construct a new instance of the GigaMart exchange.

		@param _assetHandler The address of the existing manager contract.
		@param _validator The address of a privileged validator for permitting 
			collection administrators to control their royalty fees.
		@param _protocolFeeRecipient The address which receives fees from the 
			exchange.
		@param _protocolFeePercent The percent of fees taken by 
			`_protocolFeeRecipient` in basis points (1/100th %; i.e. 200 = 2%).
	*/
	constructor (
		IAssetHandler _assetHandler,
		address _validator,
		address _protocolFeeRecipient,
		uint96 _protocolFeePercent
	) Marketplace (
		_assetHandler,
		_validator,
		_protocolFeeRecipient,
		_protocolFeePercent
	) {}

	/**
		Allow the caller to cancel an order so long as they are the maker of the 
		order.

		@param _order The `Order` data to cancel.
	*/
	function cancelOrder (
		Order calldata _order
	) external {
		_cancelOrder(_order); 
	}

	/**
		Allow the caller to cancel a set of particular orders so long as they are 
		the maker of each order.

		@param _orders An array of `Order` data to cancel.
	*/
	function cancelOrders (
		Order[] calldata _orders
	) external {
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
		_setNonce(_minNonce);
	}

	/**
		Strictly executes single orde. Reverts if the `_order` didn't pass validation 
		or item transfer failed. Also reverts on payment failure.
		
		@param _order Order struct..
		@param _signature signature for the `_order`.
		@param _recipient address of the account, which receives items or payments.
		@param _fulfillment fulfiller struct, containing information on how to fulfill
			the `_order`.

		@custom:throws InvalidRecipient if `_recipient` was not specified.
	*/
	function exchangeSingleItem (
		Order calldata _order,
		bytes calldata _signature,
		address _recipient,
		Fulfillment calldata _fulfillment
	) external payable nonReentrant {

		// Prevent the item from being sent to the zero address.
		if (_recipient == address(0)) {
			revert InvalidRecipient();
		}

		// Strictly execute the order and return eth dust.
		_executeSingle(
			_order,
			_signature,
			_recipient,
			_fulfillment
		);
	}

	/**
		Atomically executes multiple orders, emits OrderResult with error code,
		if the order didn't pass validation or item transfer failed. Reverts
		on payment failure.

		@param _executions Wrapper structs, containing orders and fulfillment indices.
		@param _signatures signatures for the orders.
		@param _recipient address of the account, which receives items or payments.
		@param _fulfillments fulfiller structs, containing information on how to 
			fulfill the orders.

		@custom:throws InvalidRecipient if `_recipient` was not specified.
	*/
	function exchangeMultipleItems (
		Execution[] calldata _executions,
		bytes[] calldata _signatures,
		address _recipient,
		Fulfillment[] calldata _fulfillments
	) external payable nonReentrant {
		
		// Prevent the item from being sent to the zero address.
		if (_recipient == address(0)) {
			revert InvalidRecipient();
		}

		// Track spent eth.
		uint256 ethSpent;

		for (uint256 i; i < _executions.length;) {
			
			/*
				Atomically execute orders, using
				fulfillments specified in Execution.fillerIndex.
			*/
			ethSpent += _executeMultiple(
				_executions[i].toOrder(),
				_signatures[i],
				_recipient,
				_fulfillments[_executions[i].fillerIndex]
			);

			unchecked {
				++i;
			}
		}

		// Return leftovers.
		if (msg.value > ethSpent) {
			msg.sender.transferEth(msg.value - ethSpent);
		}
	}

	/**
		Reads order status and fill amount.

		@param _order Order calldata pointer.

		@return _ Order status.
		@return _ Order fill amount.
	*/
	function readOrderStatus(
		Order calldata _order
	) external view returns (uint256, uint256) {
		return _readOrderStatus(_order);
	}
}