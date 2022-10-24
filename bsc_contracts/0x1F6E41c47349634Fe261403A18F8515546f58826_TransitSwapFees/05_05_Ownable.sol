// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
// Add executor extension

pragma solidity ^0.8.0;

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
abstract contract Ownable {
    address private _owner;
    address private _pendingOwner;
    address private _executor;
    address private _pendingExecutor;
    bool internal _initialized;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ExecutorshipTransferStarted(address indexed previousExecutor, address indexed newExecutor);
    event ExecutorshipTransferred(address indexed previousExecutor, address indexed newExecutor);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address newExecutor) {
        require(!_initialized, "Ownable: initialized");
        _transferOwnership(msg.sender);
        _transferExecutorship(newExecutor);
        _initialized = true;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Throws if called by any account other than the executor.
     */
    modifier onlyExecutor() {
        _checkExecutor();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the current executor.
     */
    function executor() public view virtual returns (address) {
        return _executor;
    }

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Returns the address of the pending executor.
     */
    function pendingExecutor() public view virtual returns (address) {
        return _pendingExecutor;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    /**
     * @dev Throws if the sender is not the executor.
     */
    function _checkExecutor() internal view virtual {
        require(executor() == msg.sender, "Ownable: caller is not the executor");
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
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers executorship of the contract to a new account (`newExecutor`).
     * Can only be called by the current executor.
     */
    function transferExecutorship(address newExecutor) public virtual onlyExecutor {
        _pendingExecutor = newExecutor;
        emit ExecutorshipTransferStarted(executor(), newExecutor);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        delete _pendingOwner;
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function _transferExecutorship(address newExecutor) internal virtual {
        delete _pendingExecutor;
        address oldExecutor = _executor;
        _executor = newExecutor;
        emit ExecutorshipTransferred(oldExecutor, newExecutor);
    }

    function acceptOwnership() external {
        address sender = msg.sender;
        require(pendingOwner() == sender, "Ownable: caller is not the new owner");
        _transferOwnership(sender);
    }

    function acceptExecutorship() external {
        address sender = msg.sender;
        require(pendingExecutor() == sender, "Ownable: caller is not the new executor");
        _transferExecutorship(sender);
    }
}