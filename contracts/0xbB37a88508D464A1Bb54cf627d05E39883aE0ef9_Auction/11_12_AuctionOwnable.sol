// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

import { Context } from "../oz-simplified/Context.sol";
import { Initializable } from "../oz-simplified/Initializable.sol";

import { Errors } from "../library/errors/Errors.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there are two accounts (an owner and a proxy) that can be granted exclusive
 * access to specific functions. Only the owner can set the proxy.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract AuctionOwnable is Initializable, Context {
    address private _owner;
    address private _auctioneer;
    address private _broker;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    // /**
    //  * @dev Returns the address of the current auctioneer.
    //  */
    // function auctioneer() public view virtual returns (address) {
    //     return _auctioneer;
    // }

    // /**
    //  * @dev Returns the address of the current broker.
    //  */
    // function broker() public view virtual returns (address) {
    //     return _broker;
    // }

    /**
     * @dev Returns true if the account has the auctioneer role.
     */

    function isAuctioneer(address account) public view virtual returns (bool) {
        return account == _auctioneer;
    }

    /**
     * @dev Returns true if the account has the broker role.
     */

    function isBroker(address account) public view virtual returns (bool) {
        return account == _broker;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        if (_owner != _msgSender()) revert Errors.UserPermissions();
        _;
    }

    /**
     * @dev Throws if called by any account other than the auctioneer.
     */
    modifier onlyAuctioneer() {
        if (
            _auctioneer != _msgSender()
            && _owner != _msgSender()
        ) revert Errors.UserPermissions();
        _;
    }

    /**
     * @dev Throws if called by any account other than the broker.
     */
    modifier onlyBroker() {
        if (
            _broker != _msgSender()
            && _owner != _msgSender()
        ) revert Errors.UserPermissions();
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) revert Errors.AddressTarget(newOwner);
        _setOwner(newOwner);
    }

    /**
     * @dev Sets the auctioneer for the contract to a new account (`newAuctioneer`).
     * Can only be called by the current owner.
     */
    function setAuctioneer(address newAuctioneer) public virtual onlyOwner {
        _auctioneer = newAuctioneer;
    }

    /**
     * @dev Sets the auctioneer for the contract to a new account (`newAuctioneer`).
     * Can only be called by the current owner.
     */
    function setBroker(address newBroker) public virtual onlyOwner {
        _broker = newBroker;
    }

    function _setOwner(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}