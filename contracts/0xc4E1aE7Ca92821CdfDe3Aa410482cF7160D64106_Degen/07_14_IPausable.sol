// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.10;

abstract contract IPausable {
	// Enum to represent the sale state, defaults to ``CLOSED``.
	uint8 constant CLOSED = 0;
	uint8 constant OPEN   = 1;

	// Errors
	error IPausable_INCORRECT_STATE( uint8 currentState );
	error IPausable_INVALID_STATE( uint8 newState );

	// The current state of the contract
	uint8 private _contractState;

	/**
	* @dev Emitted when the sale state changes
	*/
	event ContractStateChanged( uint8 indexed previousState, uint8 indexed newState );

	/**
	* @dev Internal function setting the contract state to `newState_`.
	* 
	* Note: Contract state can have one of 2 values by default, ``CLOSED`` or ``OPEN``.
	* 			To maintain extendability, the 2 available states are kept as uint8 instead of enum.
	* 			As a result, it is possible to set the state to an incorrect value.
	* 			To avoid issues, `newState_` should be validated before calling this function
	*/
	function _setPauseState( uint8 newState_ ) internal virtual {
		uint8 _previousState_ = _contractState;
		_contractState = newState_;
		emit ContractStateChanged( _previousState_, newState_ );
	}

	/**
	* @dev Internal function returning the contract state.
	*/
	function getPauseState() public virtual view returns ( uint8 ) {
		return _contractState;
	}

	/**
	* @dev Throws if sale state is not ``CLOSED``.
	*/
	modifier isClosed {
		if ( _contractState != CLOSED ) {
			revert IPausable_INCORRECT_STATE( _contractState );
		}
		_;
	}

	/**
	* @dev Throws if sale state is ``CLOSED``.
	*/
	modifier isNotClosed {
		if ( _contractState == CLOSED ) {
			revert IPausable_INCORRECT_STATE( _contractState );
		}
		_;
	}

	/**
	* @dev Throws if sale state is not ``OPEN``.
	*/
	modifier isOpen {
		if ( _contractState != OPEN ) {
			revert IPausable_INCORRECT_STATE( _contractState );
		}
		_;
	}

	/**
	* @dev Throws if sale state is ``OPEN``.
	*/
	modifier isNotOpen {
		if ( _contractState == OPEN ) {
			revert IPausable_INCORRECT_STATE( _contractState );
		}
		_;
	}
}