// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/**
* Author: Lambdalf the White
*/

abstract contract IPausable {
	// Errors
	error IPausable_SALE_NOT_CLOSED();
	error IPausable_SALE_NOT_OPEN();
	error IPausable_PRESALE_NOT_OPEN();

	// Enum to represent the sale state, defaults to ``CLOSED``.
	enum SaleState { CLOSED, PRESALE, SALE }

	// The current state of the contract
	SaleState public saleState;

	/**
	* @dev Emitted when the sale state changes
	*/
	event SaleStateChanged( SaleState indexed previousState, SaleState indexed newState );

	/**
	* @dev Sale state can have one of 3 values, ``CLOSED``, ``PRESALE``, or ``SALE``.
	*/
	function _setSaleState( SaleState newState_ ) internal virtual {
		SaleState _previousState_ = saleState;
		saleState = newState_;
		emit SaleStateChanged( _previousState_, newState_ );
	}

	/**
	* @dev Throws if sale state is not ``CLOSED``.
	*/
	modifier saleClosed {
		if ( saleState != SaleState.CLOSED ) {
			revert IPausable_SALE_NOT_CLOSED();
		}
		_;
	}

	/**
	* @dev Throws if sale state is not ``SALE``.
	*/
	modifier saleOpen {
		if ( saleState != SaleState.SALE ) {
			revert IPausable_SALE_NOT_OPEN();
		}
		_;
	}

	/**
	* @dev Throws if sale state is not ``PRESALE``.
	*/
	modifier presaleOpen {
		if ( saleState != SaleState.PRESALE ) {
			revert IPausable_PRESALE_NOT_OPEN();
		}
		_;
	}
}