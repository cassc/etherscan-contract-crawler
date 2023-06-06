// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import {
	EscapeHatch,
	IERC20,
	SafeERC20
} from "./EscapeHatch.sol";

import {
	AggregatorTradeFinalizer
} from "../AggregatorTradeFinalizer.sol";

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title Configuration
	@author Rostislav Khlebnikov <@catpic5buck>
	@custom:contributor Tim Clancy <@_Enoch>
	
	This contract contains configuration controls for the GigaMart aggregator.

	@custom:date January 23rd, 2023.
*/
abstract contract Configuration is EscapeHatch {

	uint256 internal constant _FLAG = 
		0x0000000000000000000000000000000100000000000000000000000000000000;

	/// The identifier for the right to adjust the aggregator configuration.
	bytes32 private constant AGGREGATOR_CONFIG = keccak256("AGGREGATOR_CONFIG");

	/// A mapping to track flags for supported exchange addresses.
	mapping ( address => uint256 ) public supportedExchanges;

	/// Store an immutable reference to delegate contract.
	AggregatorTradeFinalizer public finalizer;

	/**
		Construct an instance of the GigaMart aggregator configuration.

		@param _exchanges An array of exchange addresses to mark as supported.
		@param _tokens An array of payment tokens to approve to `_transferProxies`.
		@param _transferProxies An array of addresses to set approval for on behalf 
			of this contract.
		@param _governance The address of a caller which has rights to manage 
			payment tokens.
		@param _rescuer An address that can pause or unpause the contract and 
			rescue assets.
	*/
	constructor (
		address[] memory _exchanges,
		address[] memory _tokens,
		address[] memory _transferProxies,
		address _governance,
		address _rescuer
	) EscapeHatch(_rescuer) {


		// Immediately flag any provided exchanges as supported.
		for (uint256 i; i < _exchanges.length; ) {
			supportedExchanges[_exchanges[i]] += _FLAG;
			unchecked {
				++i;
			}
		}

		// Approve any provided tokens for use on the exchanges.
		for (uint256 j; j < _transferProxies.length; ) {
			for (uint256 k; k < _tokens.length; ) {
				IERC20(_tokens[k]).approve(
					_transferProxies[j],
					type(uint256).max
				);
				unchecked {
					++k;
				}
			}
			unchecked {
				++j;
			}
		}

		// Set the permit of the aggregator configurator.
		setPermit(_governance, UNIVERSAL, AGGREGATOR_CONFIG, type(uint256).max);
	}

	/**
		Set and initialize a new aggregation finalizer, used for handling certain 
		exchanges (LooksRare and X2Y2) which do not support direct recipients of 
		3rd party purchased items.

		@param _finalizer The address of a new aggregation finalizer contract.
	*/
	function changeFinalizer (
		AggregatorTradeFinalizer _finalizer
	) external hasValidPermit(UNIVERSAL, AGGREGATOR_CONFIG) {
		finalizer = _finalizer;
		address(finalizer).delegatecall(abi.encodePacked(bytes4(keccak256("initialize()"))));
	}

	/**
		Set approval on the given array `_tokens` of payment tokens to each 
		transfer proxy in `_transferProxies`.

		@param _tokens An array of payment tokens to approve `transferProxies` to 
			spend.
		@param _transferProxies An array of addresses to set approvals for on 
			behalf of this contract.
	*/
	function addPaymentTokens (
		address[] calldata _tokens,
		address[] calldata _transferProxies
	) external hasValidPermit(UNIVERSAL, AGGREGATOR_CONFIG) {
		for (uint256 i; i < _transferProxies.length; ) {
			for (uint256 j; j < _tokens.length; ) {

				// Approve each token on each proxy.
				IERC20(_tokens[j]).approve(
					_transferProxies[i],
					type(uint256).max
				);
				unchecked {
					++j;
				}
			}
			unchecked {
				++i;
			}
		}
	}

	/**
		Revoke approval on the given array `_tokens` of payment tokens from each 
		transfer proxy in `_transferProxies`.

		@param _tokens An array of payment tokens to revoke approval of 
			`transferProxies` to spend.
		@param _transferProxies An array of addresses to revoke approvals from on 
			behalf of this contract.
	*/
	function removePaymentTokens (
		address[] calldata _tokens,
		address[] calldata _transferProxies
	) external hasValidPermit(UNIVERSAL, AGGREGATOR_CONFIG) {
		for (uint256 i; i < _transferProxies.length; ) {
			for (uint256 j; j < _tokens.length; ) {

				// Revoke approval for each token on each proxy.
				IERC20(_tokens[j]).approve(_transferProxies[i], 0);
				unchecked {
					++j;
				}
			}
			unchecked {
				++i;
			}
		}
	}

	/**
		Include `_exchange` for order aggregation.

		@param _exchange An array of payment tokens to revoke approval of 
			`transferProxies` to spend.
	*/
	function addExchange (
		address _exchange
	) external hasValidPermit(UNIVERSAL, AGGREGATOR_CONFIG) {
		supportedExchanges[_exchange] += _FLAG;
	}

	/**
		Exclude `_exchange` from order aggregation.

		@param _exchange An array of payment tokens to revoke approval of 
			`transferProxies` to spend.
	*/
	function removeExchange (
		address _exchange
	) external hasValidPermit(UNIVERSAL, AGGREGATOR_CONFIG) {
		supportedExchanges[_exchange] = 0;
	}
}