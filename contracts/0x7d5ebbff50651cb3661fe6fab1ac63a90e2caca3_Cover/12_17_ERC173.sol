// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

import "../interfaces/IERC173.sol";
import "../interfaces/IERC173Errors.sol";

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
abstract contract ERC173 is IERC173, IERC173Errors {
  // The owner of the contract
  address private _owner;

  // **************************************
  // *****          MODIFIER          *****
  // **************************************
    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
      if (owner() != msg.sender) {
        revert IERC173_NOT_OWNER(msg.sender);
      }
      _;
    }
  // **************************************

  // **************************************
  // *****          INTERNAL          *****
  // **************************************
    /**
    * @dev Sets the contract owner.
    * 
    * Note: This function needs to be called in the contract constructor to initialize the contract owner, 
    * if it is not, then parts of the contract might be non functional
    * 
    * @param owner_ : address that owns the contract
    */
    function _setOwner(address owner_) internal {
      _owner = owner_;
    }
  // **************************************

  // **************************************
  // *****       CONTRACT OWNER       *****
  // **************************************
    /**
    * @dev Transfers ownership of the contract to `newOwner_`.
    * 
    * @param newOwner_ : address of the new contract owner
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    */
    function transferOwnership(address newOwner_) public virtual onlyOwner {
      address _oldOwner_ = _owner;
      _owner = newOwner_;
      emit OwnershipTransferred(_oldOwner_, newOwner_);
    }
  // **************************************

  // **************************************
  // *****            VIEW            *****
  // **************************************
    /**
    * @dev Returns the address of the current contract owner.
    * 
    * @return address : the current contract owner
    */
    function owner() public view virtual returns (address) {
      return _owner;
    }
  // **************************************
}