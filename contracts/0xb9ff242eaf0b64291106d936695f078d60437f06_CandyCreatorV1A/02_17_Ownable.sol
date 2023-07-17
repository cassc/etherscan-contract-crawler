/***
 *     ██████╗ ██╗    ██╗███╗   ██╗ █████╗ ██████╗ ██╗     ███████╗
 *    ██╔═══██╗██║    ██║████╗  ██║██╔══██╗██╔══██╗██║     ██╔════╝
 *    ██║   ██║██║ █╗ ██║██╔██╗ ██║███████║██████╔╝██║     █████╗  
 *    ██║   ██║██║███╗██║██║╚██╗██║██╔══██║██╔══██╗██║     ██╔══╝  
 *    ╚██████╔╝╚███╔███╔╝██║ ╚████║██║  ██║██████╔╝███████╗███████╗
 *     ╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═══╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝
 * Re-write of @openzeppelin/contracts/access/Ownable.sol
 * 
 *
 * Upgraded to push/pull and decline compared to original contract
 */

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1
// Rewritten for onlyOwner modifier

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (a owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the Owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwner}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the Owner.
 */

abstract contract Ownable is Context {

    address private _Owner;
    address private _newOwner;

    event OwnerTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial Owner.
     */
    constructor() {
        _transferOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current Owner.
     */
    function owner() public view virtual returns (address) {
        return _Owner;
    }

    /**
     * @dev Throws if called by any account other than the Owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Owner: caller is not the Owner");
        _;
    }

    /**
     * @dev Leaves the contract without Owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current Owner.
     *
     * NOTE: Renouncing Ownership will leave the contract without an Owner,
     * thereby removing any functionality that is only available to the Owner.
     */
    function renounceOwner() public virtual onlyOwner {
        _transferOwner(address(0));
    }

    /**
     * @dev Transfers Owner of the contract to a new account (`newOwner`).
     * Can only be called by the current Owner. Now push/pull.
     */
    function transferOwner(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Owner: new Owner is the zero address");
        _newOwner = newOwner;
    }

    /**
     * @dev Accepts Transfer Owner of the contract to a new account (`newOwner`).
     * Can only be called by the new Owner. Pull Accepted.
     */
    function acceptOwner() public virtual {
        require(_newOwner == _msgSender(), "New Owner: new Owner is the only caller");
        _transferOwner(_newOwner);
    }

    /**
     * @dev Declines Transfer Owner of the contract to a new account (`newOwner`).
     * Can only be called by the new Owner. Pull Declined.
     */
    function declineOwner() public virtual {
        require(_newOwner == _msgSender(), "New Owner: new Owner is the only caller");
        _newOwner = address(0);
    }

    /**
     * @dev Transfers Owner of the contract to a new account (`newOwner`).
     * Can only be called by the current Owner. Now push only. Orginal V1 style
     */
    function pushOwner(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Owner: new Owner is the zero address");
        _transferOwner(newOwner);
    }

    /**
     * @dev Transfers Owner of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwner(address newOwner) internal virtual {
        address oldOwner = _Owner;
        _Owner = newOwner;
        emit OwnerTransferred(oldOwner, newOwner);
    }
}