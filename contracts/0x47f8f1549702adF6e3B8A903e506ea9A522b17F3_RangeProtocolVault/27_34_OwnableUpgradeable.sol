// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an manager) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the manager account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyManager`, which can be applied to your functions to restrict their use to
 * the manager.
 */
contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _manager;

    event OwnershipTransferred(address indexed previousManager, address indexed newManager);

    /**
     * @dev Initializes the contract setting the deployer as the initial manager.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the manager.
     */
    modifier onlyManager() {
        _checkManager();
        _;
    }

    /**
     * @dev Returns the address of the current manager.
     */
    function manager() public view virtual returns (address) {
        return _manager;
    }

    /**
     * @dev Throws if the sender is not the manager.
     */
    function _checkManager() internal view virtual {
        require(manager() == _msgSender(), "Ownable: caller is not the manager");
    }

    /**
     * @dev Leaves the contract without manager. It will not be possible to call
     * `onlyManager` functions anymore. Can only be called by the current manager.
     *
     * NOTE: Renouncing ownership will leave the contract without a manager,
     * thereby removing any functionality that is only available to the manager.
     */
    function renounceOwnership() public virtual onlyManager {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newManager`).
     * Can only be called by the current manager.
     */
    function transferOwnership(address newManager) public virtual onlyManager {
        require(newManager != address(0), "Ownable: new manager is the zero address");
        _transferOwnership(newManager);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newManager`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newManager) internal virtual {
        address oldManager = _manager;
        _manager = newManager;
        emit OwnershipTransferred(oldManager, newManager);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}