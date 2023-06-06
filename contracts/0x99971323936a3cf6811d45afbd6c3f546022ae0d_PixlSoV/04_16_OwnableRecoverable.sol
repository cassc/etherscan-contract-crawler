// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";
/**
 * This is a modified version of the standard OpenZeppelin Ownable contract that allows for a recovery address to be used to recover ownership
 * 
 * 
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
abstract contract OwnableRecoverable is Context {
    address private _owner;

    // the recovery address can be used to recover ownership if the owner wallet is ever lost
    // it should be a cold-storage wallet stored in a vault and never used for any other operation
    // it should be set in the parent constructor
    // if ownership moves to a new organization then the recovery address should be moved too
    address public recovery;

    // initializes the contract setting the deployer as the initial owner.
    constructor () {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "caller not owner");
        _;
    }

    modifier onlyOwnerOrRecovery() {
        require(_msgSender() == owner() || _msgSender() == recovery, "caller not owner/recovery");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwnerOrRecovery {
        require(newOwner != address(0), "cant use 0 addr");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        _owner = newOwner;
    }   

    // the recovery address can be changed by the owner or the recovery address
    function setRecovery(address newRecovery) public virtual onlyOwnerOrRecovery {   
        require(newRecovery != address(0), "cant use 0 addr");
        recovery = newRecovery;
    }
    

}