// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import {
	ReentrancyGuard
} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {
	Configuration,
	EscapeHatch,
	AggregatorTradeFinalizer,
	IERC20,
	SafeERC20
} from "./lib/Configuration.sol";
import {
	TokenTransferProxy
} from "../marketplace/proxy/TokenTransferProxy.sol";
import {
	NativeTransfer
} from "./../marketplace/libraries/NativeTransfer.sol";

/**
	Thrown if an Ether payment to the aggregator does not match the provided 
	message value.

	@param paymentAmount The payment amount to match with the message value.
	@param messageValue The message value to match.
*/
error ExpectedValueDiffers (
	uint256 paymentAmount,
	uint256 messageValue
);

/// Thrown if purchases in the aggregator are paused.
error Paused ();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title GigaMart Aggregator
	@author Rostislav Khlebnikov <@catpic5buck>
	@custom:contributor Tim Clancy <@_Enoch>
	
	This contract implements a multi-market aggregator for GigaMart.

	@custom:version 1.2
	@custom:date Januart 24th, 2023.
*/
contract GigaAggregator is Configuration, ReentrancyGuard {
	using SafeERC20 for IERC20;
	using NativeTransfer for address;

	/// A name used for this contract.
	string public constant name = "GigaAggregator v1.2";

	/// Track the slot for a supported exchange.
	uint256 private constant _SUPPORTED_EXCHANGES_SLOT = 4;

	/**
		A convenience struct to contain information regarding total payment amounts 
		accross all orders.

		@param asset The address of a payment token.
		@param amount The amount of asset being paid.
	*/
	struct Payment {
		address asset;
		uint256 amount;
	}

	/// Store an immutable reference to a token transfer proxy.
	TokenTransferProxy public immutable TOKEN_TRANSFER_PROXY;

	/**
		Construct a new GigaMart aggregator.

		@param _exchanges An array of exchange addresses to mark as supported.
		@param _tokens An array of payment tokens to approve to `_transferProxies`.
		@param _transferProxies An array of addresses to set approval for on behalf 
			of this contract.
		@param _tokenTransferProxy The address of a token transfer proxy.
		@param _governance The address of a caller which has rights to manage 
			payment tokens.
		@param _rescuer An address that can pause or unpause the contract and 
			rescue assets.
	*/
	constructor (
		address[] memory _exchanges,
		address[] memory _tokens,
		address[] memory _transferProxies,
		TokenTransferProxy _tokenTransferProxy,
		address _governance,
		address _rescuer
	) Configuration(
		_exchanges,
		_tokens,
		_transferProxies,
		_governance,
		_rescuer
	) {
		TOKEN_TRANSFER_PROXY = _tokenTransferProxy;
	}

	/// Add a payable receive function so that the aggregator can receive Ether.
	receive () external payable { }

	/// Return the magic value signifying the ability to receive ERC-721 items.
	function onERC721Received (
		address,
		address,
		uint256,
		bytes memory
	) public pure returns (bytes4) {
		return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
	}

	/// Return the magic value signifying the ability to receive ERC-1155 items.
	function onERC1155Received (
		address,
		address,
		uint256,
		uint256,
		bytes memory
	) public pure returns (bytes4) {
		return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
	}

	/// Return the magic value signifying the ability to batch receive ERC-1155.
	function onERC1155BatchReceived (
		address,
		address,
		uint256[] memory,
		uint256[] memory,
		bytes memory
	) public pure returns (bytes4) {
		return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
	}

	/**
		Reads balances of this contract on payment assets.

		@param _payments An array containing information about token addresses and 
			the total token amounts needed to purchase all orders in the cart.
		@param _balances An array for accumulating the balance of this contract for 
			each asset.
	*/
	function _readBalances (
		Payment[] calldata _payments,
		uint256[] memory _balances
	) private view {
		for (uint256 i; i < _payments.length; ) {

			/*
				Determine the balance of this aggregator contract in either Ether or 
				ERC-20 token, depending on the payment asset.
			*/
			_balances[i] = _payments[i].asset == address(0)
				? address(this).balance - msg.value
				: IERC20(_payments[i].asset).balanceOf(address(this));
			unchecked {
				++i;
			}
		}
	}

	/**
		This function transfers ERC-20 tokens to this aggregator contract which 
		later will be used for executing purchases from cart. The function also 
		verifies native payment.

		@param _payments An array containing information about token addresses and 
			the total token amounts needed to purchase all orders in the cart.

		@custom:throws ExpectedValueDiffers if the message value does not match a 
			provided Ether payment amount.
	*/
	function _gatherPayments (
		Payment[] calldata _payments
	) private {
		for (uint256 i; i < _payments.length; ) {

			// Revert if there is a mismatched Ether balance.
			bool native = _payments[i].asset == address(0);
			if (native && _payments[i].amount != msg.value) {
				revert ExpectedValueDiffers(_payments[i].amount, msg.value);
			}

			// Transfer ERC-20 tokens.
			if (!native) {
				TOKEN_TRANSFER_PROXY.transferERC20(
					_payments[i].asset,
					msg.sender,
					address(this),
					_payments[i].amount
				);	
			}
			unchecked {
				++i;
			}
		}
	}

	/**
		Parse the cart and call targeted exchanges.

		@param _cart The cart to fulfill item purchase calls from.
	*/
	function _buy (
		bytes calldata _cart
	) private {

		// An offset to the start of the cart full of calls.
		uint256 offset = 0x64;
		while (offset < _cart.length) {
			assembly {

				// Retrieve the length of this call.
				let length := calldataload(add(offset, 0x20))

				// Retrieve the exchange for fulfilling purchase of this call.
				let exchange := calldataload(offset)
				
				// Store the exchange and a mapping slot into memory.
				mstore(0x00, exchange)
				mstore(0x20, _SUPPORTED_EXCHANGES_SLOT)

				/*
					Hash the exchange and its storage slot, then load the resulting 
					address of the storage slot into memory. If the exchange is 
					supported, continue.
				*/
				let supported := sload(keccak256(0x00, 0x40))
				if  shr(0x80, supported) {
					
					// Load the free memory pointer.
					let ptr := mload(0x40)

					// Copy the call into memory.
					calldatacopy(ptr, add(offset, 0x60), length)

					// Pop the result of the call from the stack, ignoring it.
					let result :=
						
						// Perform the call from the cart.
						call(
							gas(),
							exchange,
							calldataload(add(offset, 0x40)),
							ptr,
							length,
							0,
							0
						)

					/*
						Transfer acquired assets (only needed when working with specific 
						marketplaces which do not support recipients).
					*/
					if and(result, eq(shl(0x80, supported), _FLAG)) {
						pop(
							delegatecall(
								gas(),
								sload(finalizer.slot),
								ptr,
								length,
								0,
								0
							)
						)
					}
				}

				// Iterate to the next call in the cart.
				offset := add(offset, add(length, 0x60))
			}
		}
	}

	/**
		Return unused payment assets back to the message sender.

		@param _payments An array containing information about token addresses and 
			the total token amounts needed to purchase all orders in the cart.
		@param _balances An array containing the balances of payment assets in this 
			contract.
	*/
	function _returnLeftovers (
		Payment[] calldata _payments,
		uint256[] memory _balances
	) private {
		uint256 current;
		for (uint256 i; i < _balances.length; ) {
			unchecked {

				// Attempt to return Ether.
				if (_payments[i].asset == address(0)) {
					current = address(this).balance;
					if (current > _balances[i]) {
						msg.sender.transferEth(current - _balances[i]);
					}

				// Otherwise, attempt to return an ERC-20 token.
				} else {
					current = IERC20(_payments[i].asset).balanceOf(
						address(this)
					);
					if (current > _balances[i]) {
						IERC20(_payments[i].asset).safeTransfer(
							msg.sender,
							current - _balances[i]
						);
					}
				}
				++i;
			}
		}
	}

	/**
		Parse the incoming cart, verify payments status, gracefuly execute orders, 
		and return payments for failed orders.

		@param _cart A bytes array containing encoded calls to exchanges with the 
			exchange, call length, and Ether value as a prefix to each call. For 
			example:
			cart = encode(
				exchange, length, value, call,
				...
				exchange(n), length(n), value(n), call(n)
			)
			... where n is an index of a call.

		@param _payments An array containing information about token addresses and 
			the total token amounts needed to purchase all orders in the cart.

		@custom:throws Paused if purchases on the aggregator have been paused.
	*/
	function purchase (
		bytes calldata _cart,
		Payment[] calldata _payments
	) external payable nonReentrant {
		if (_status == EscapeHatch.Status.Paused) {
			revert Paused();
		}

		// Accumulate the balance of this contract for each payment asset.
		uint256[] memory balances = new uint256[](_payments.length);
		_readBalances(_payments, balances);
		
		// Gather payment assets to the aggregator.
		_gatherPayments(_payments);

		// Perform the asset purchase.
		_buy(_cart);

		// Return leftover balances.
		_returnLeftovers(_payments, balances);
	}
}