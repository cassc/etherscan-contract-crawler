// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

abstract contract IPausable {
	// Enum to represent the sale state, defaults to ``PAUSED``.
	uint8 public constant PAUSED = 0;

	// Errors
	/**
	* @dev Thrown when a function is called with the wrong contract state.
	* 
	* @param currentState : the current state of the contract
	*/
	error IPausable_INCORRECT_STATE( uint8 currentState );
	/**
	* @dev Thrown when trying to set the contract state to an invalid value.
	* 
	* @param invalidState : the invalid contract state
	*/
	error IPausable_INVALID_STATE( uint8 invalidState );

	// The current state of the contract
	uint8 private _contractState;

	/**
	* @dev Emitted when the sale state changes
	*/
	event ContractStateChanged( uint8 indexed previousState, uint8 indexed newState );

	/**
	* @dev Ensures that contract state is `expectedState_`.
	* 
	* @param expectedState_ : the desirable contract state
	*/
	modifier isState( uint8 expectedState_ ) {
		if ( _contractState != expectedState_ ) {
			revert IPausable_INCORRECT_STATE( _contractState );
		}
		_;
	}

	/**
	* @dev Ensures that contract state is not `unexpectedState_`.
	* 
	* @param unexpectedState_ : the undesirable contract state
	*/
	modifier isNotState( uint8 unexpectedState_ ) {
		if ( _contractState == unexpectedState_ ) {
			revert IPausable_INCORRECT_STATE( _contractState );
		}
		_;
	}

	/**
	* @dev Internal function setting the contract state to `newState_`.
	* 
	* Note: Contract state defaults to ``PAUSED``.
	* 			To maintain extendability, this value kept as uint8 instead of enum.
	* 			As a result, it is possible to set the state to an incorrect value.
	* 			To avoid issues, `newState_` should be validated before calling this function
	*/
	function _setPauseState( uint8 newState_ ) internal virtual {
		uint8 _previousState_ = _contractState;
		_contractState = newState_;
		emit ContractStateChanged( _previousState_, newState_ );
	}

	/**
	* @dev Returns the current contract state.
	* 
	* @return uint8 : the current contract state
	*/
	function getPauseState() public virtual view returns ( uint8 ) {
		return _contractState;
	}
}