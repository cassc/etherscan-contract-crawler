// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

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
abstract contract OwnableTimelockUpgradeable is Initializable, ContextUpgradeable {
    error CallerIsNotTimelockOwner();
    error ZeroTimelockAddress();

    address private _timelockOwner;

    event TimelockOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __OwnableTimelock_init() internal onlyInitializing {
        __OwnableTimelock_init_unchained();
    }

    function __OwnableTimelock_init_unchained() internal onlyInitializing {
        _transferTimelockOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyTimelock() {
        _checkTimelockOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function timelockOwner() public view virtual returns (address) {
        return _timelockOwner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkTimelockOwner() internal view virtual {
        if (timelockOwner() != _msgSender()) revert CallerIsNotTimelockOwner();
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceTimelockOwnership() public virtual onlyTimelock {
        _transferTimelockOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferTimelockOwnership(address newOwner) public virtual onlyTimelock {
        if (newOwner == address(0)) revert ZeroTimelockAddress();
        _transferTimelockOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferTimelockOwnership(address newOwner) internal virtual {
        address oldOwner = _timelockOwner;
        _timelockOwner = newOwner;
        emit TimelockOwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}