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

    address private _executor;
    address private _pendingExecutor;
    bool internal _initialized;

    event ExecutorshipTransferStarted(address indexed previousExecutor, address indexed newExecutor);
    event ExecutorshipTransferred(address indexed previousExecutor, address indexed newExecutor);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address newExecutor) {
        require(!_initialized, "Ownable: initialized");
        _transferExecutorship(newExecutor);
        _initialized = true;
    }

    /**
     * @dev Throws if called by any account other than the executor.
     */
    modifier onlyExecutor() {
        _checkExecutor();
        _;
    }

    /**
     * @dev Returns the address of the current executor.
     */
    function executor() public view virtual returns (address) {
        return _executor;
    }

    /**
     * @dev Returns the address of the pending executor.
     */
    function pendingExecutor() public view virtual returns (address) {
        return _pendingExecutor;
    }

    /**
     * @dev Throws if the sender is not the executor.
     */
    function _checkExecutor() internal view virtual {
        require(executor() == msg.sender, "Ownable: caller is not the executor");
    }

    /**
     * @dev Transfers executorship of the contract to a new account (`newExecutor`).
     * Can only be called by the current executor.
     */
    function transferExecutorship(address newExecutor) public virtual onlyExecutor {
        _pendingExecutor = newExecutor;
        emit ExecutorshipTransferStarted(executor(), newExecutor);
    }

    function _transferExecutorship(address newExecutor) internal virtual {
        delete _pendingExecutor;
        address oldExecutor = _executor;
        _executor = newExecutor;
        emit ExecutorshipTransferred(oldExecutor, newExecutor);
    }

    function acceptExecutorship() external {
        address sender = msg.sender;
        require(pendingExecutor() == sender, "Ownable: caller is not the new executor");
        _transferExecutorship(sender);
    }
}