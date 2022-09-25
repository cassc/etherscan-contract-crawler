// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
* Edit  : Squeebo
*/

pragma solidity 0.8.17;

abstract contract IWhitelistable_ECDSA {
	// Errors
  /**
  * @dev Thrown when trying to query the whitelist while it's not set
  */
	error IWhitelistable_NOT_SET();
  /**
  * @dev Thrown when `account` has consumed their alloted access and tries to query more
  * 
  * @param account : address trying to access the whitelist
  */
	error IWhitelistable_CONSUMED( address account );
  /**
  * @dev Thrown when `account` does not have enough alloted access to fulfil their query
  * 
  * @param account : address trying to access the whitelist
  */
	error IWhitelistable_FORBIDDEN( address account );

	/**
  * @dev A structure representing a signature proof to be decoded by the contract
  */
	struct Proof {
		bytes32 r;
		bytes32 s;
		uint8   v;
	}

	address private _adminSigner;
	mapping( uint8 => mapping ( address => uint256 ) ) private _consumed;

	/**
	* @dev Ensures that `account_` has `qty_` alloted access on the `whitelistId_` whitelist.
	* 
	* @param account_     : the address to validate access
	* @param whitelistId_ : the identifier of the whitelist being queried
	* @param alloted_     : the max amount of whitelist spots allocated
	* @param proof_       : the signature proof to validate whitelist allocation
	* @param qty_         : the amount of whitelist access requested
	*/
	modifier isWhitelisted( address account_, uint8 whitelistId_, uint256 alloted_, Proof memory proof_, uint256 qty_ ) {
		uint256 _allowed_ = checkWhitelistAllowance( account_, whitelistId_, alloted_, proof_ );

		if ( _allowed_ < qty_ ) {
			revert IWhitelistable_FORBIDDEN( account_ );
		}

		_;
	}

	/**
	* @dev Sets the pass to protect the whitelist.
	* 
	* @param adminSigner_ : the address validating the whitelist signatures
	*/
	function _setWhitelist( address adminSigner_ ) internal virtual {
		_adminSigner = adminSigner_;
	}

	/**
	* @dev Returns the amount that `account_` is allowed to access from the whitelist.
	* 
	* @param account_     : the address to validate access
	* @param whitelistId_ : the identifier of the whitelist being queried
	* @param alloted_     : the max amount of whitelist spots allocated
	* @param proof_       : the signature proof to validate whitelist allocation
	* 
	* @return uint256 : the total amount of whitelist allocation remaining for `account_`
	* 
	* Requirements:
	* 
	* - `_adminSigner` must be set.
	*/
	function checkWhitelistAllowance( address account_, uint8 whitelistId_, uint256 alloted_, Proof memory proof_ ) public view returns ( uint256 ) {
		if ( _adminSigner == address( 0 ) ) {
			revert IWhitelistable_NOT_SET();
		}

		if ( _consumed[ whitelistId_ ][ account_ ] >= alloted_ ) {
			revert IWhitelistable_CONSUMED( account_ );
		}

		if ( ! _validateProof( account_, whitelistId_, alloted_, proof_ ) ) {
			revert IWhitelistable_FORBIDDEN( account_ );
		}

		return alloted_ - _consumed[ whitelistId_ ][ account_ ];
	}

	/**
	* @dev Internal function to decode a signature and compare it with the `_adminSigner`.
	* 
	* @param account_     : the address to validate access
	* @param whitelistId_ : the identifier of the whitelist being queried
	* @param alloted_     : the max amount of whitelist spots allocated
	* @param proof_       : the signature proof to validate whitelist allocation
	* 
	* @return bool : whether the signature is valid or not
	*/ 
	function _validateProof( address account_, uint8 whitelistId_, uint256 alloted_, Proof memory proof_ ) private view returns ( bool ) {
		bytes32 _digest_ = keccak256( abi.encode( whitelistId_, alloted_, account_ ) );
		address _signer_ = ecrecover( _digest_, proof_.v, proof_.r, proof_.s );
		return _signer_ == _adminSigner;
	}

	/**
	* @dev Consumes `amount_` whitelist access passes from `account_`.
	* 
	* @param account_     : the address to consume access from
	* @param whitelistId_ : the identifier of the whitelist being queried
	* @param qty_         : the amount of whitelist access consumed
	* 
	* Note: Before calling this function, eligibility should be checked through {IWhitelistable-checkWhitelistAllowance}.
	*/
	function _consumeWhitelist( address account_, uint8 whitelistId_, uint256 qty_ ) internal {
		unchecked {
			_consumed[ whitelistId_ ][ account_ ] += qty_;
		}
	}
}