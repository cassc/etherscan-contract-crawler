// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

import "../interfaces/IERC173.sol";

/**
* @dev Contract module which provides a basic access control mechanism, where
* there is an account (an owner) that can be granted exclusive access to
* specific functions.
*
* By default, the owner account will be the one that deploys the contract. This
* can later be changed with {transferOwnership}.
*
* This module is used through inheritance. It will make available the modifier
* `onlyOwner`, which can be applied to your functions to restrict their use to
* the owner.
*/
abstract contract IOwnable is IERC173 {
	// Errors
  /**
  * @dev Thrown when `operator` is not the contract owner.
  * 
  * @param operator : address trying to use a function reserved to contract owner without authorization
  */
  error IERC173_NOT_OWNER( address operator );

	// The owner of the contract
	address private _owner;

	/**
	* @dev Throws if called by any account other than the owner.
	*/
	modifier onlyOwner() {
		address _sender_ = msg.sender;
		if ( owner() != _sender_ ) {
			revert IERC173_NOT_OWNER( _sender_ );
		}
		_;
	}

	/**
	* @dev Initializes the contract setting `owner_` as the initial owner.
	* 
	* Note: This function needs to be called in the contract constructor to initialize the contract owner, 
	* if it is not, then parts of the contract might be non functional
	* 
	* @param owner_ : address that owns the contract
	*/
	function _initIOwnable( address owner_ ) internal {
		_owner = owner_;
	}

	/**
	* @dev Returns the address of the current owner.
	* 
	* @return address : the current contract owner
	*/
	function owner() public view virtual returns ( address ) {
		return _owner;
	}

	/**
	* @dev Transfers ownership of the contract to `newOwner`.
	* 
	* @param newOwner_ : address of the new contract owner
	* 
	* Requirements:
	* 
  * - Caller must be the contract owner.
	*/
	function transferOwnership( address newOwner_ ) public virtual onlyOwner {
		address _oldOwner_ = _owner;
		_owner = newOwner_;
		emit OwnershipTransferred( _oldOwner_, newOwner_ );
	}
}