// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;
    address private _reviewer;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ReviewershipTransferred(address indexed previousReviewer, address indexed newReviewer);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner and reviewer.
     */
    constructor() {
        _transferOwnership(_msgSender());
        _transferReviewership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev Throws if called by any account other than the reviewer.
     */
    modifier multiReviewer() {
        _checkMultiReviewer();
        _;
    }

    /**
     * @dev Returns the address of the current reviewer.
     */
    function reviewer() public view virtual returns (address) {
        return _reviewer;
    }

    /**
     * @dev Throws if the sender is not the reviewer.
     */
    function _checkMultiReviewer() internal view virtual {
        require(reviewer() == _msgSender() || owner() == _msgSender(), "Ownable: caller is not the reviewer");
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newReviewer`).
     * Can only be called by the current reviewer.
     */
    function transferReviewership(address newReviewer) public virtual onlyOwner {
        require(newReviewer != address(0), "Ownable: new reviewer is the zero address");
        _transferReviewership(newReviewer);
    }

     /**
     * @dev Transfers reviewership of the contract to a new account (`newReviewer`).
     * Internal function without access restriction.
     */
    function _transferReviewership(address newReviewer) internal virtual {
        address oldReviewer = _reviewer;
        _reviewer = newReviewer;
        emit ReviewershipTransferred(oldReviewer, newReviewer);
    }
}