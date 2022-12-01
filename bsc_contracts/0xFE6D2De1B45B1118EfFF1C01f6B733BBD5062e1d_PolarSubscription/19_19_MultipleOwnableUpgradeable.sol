// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there are multiple owners and a super owner that can be granted exclusive 
 * access to specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract MultipleOwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _superOwner;

    address[] private _owners;

    mapping(address => bool) public owners;
    
    event SuperOwnershipTransferred(address indexed previousSuperOwner, address indexed newSuperOwner);

    event OwnershipChanged(address indexed owner, bool indexed status);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init(address[] calldata _initialOwners) internal onlyInitializing {
        __Ownable_init_unchained(_initialOwners);
    }

    function __Ownable_init_unchained(address[] calldata _initialOwners) internal onlyInitializing {
        _transferSuperOwnership(_msgSender());
        for (uint i = 0; i < _initialOwners.length; i++) {
            _grantOwnership(_initialOwners[i]);
        }
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlySuperOwner() {
        _checkSuperOwner();
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current super owner.
     */
    function superOwner() public view virtual returns (address) {
        return _superOwner;
    }

    /**
     * @dev Throws if the sender is not the super owner.
     */
    function _checkSuperOwner() internal view virtual {
        require(superOwner() == _msgSender(), "Ownable: caller is not the super owner");
    }

    /**
     * @dev Throws if the sender is not an owner.
     */
    function _checkOwner() internal view virtual {
        require(owners[_msgSender()] || superOwner() == _msgSender(), "Ownable: caller is not an owner");
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newSuperOwner`).
     * Can only be called by the current owner.
     */
    function transferSuperOwnership(address newSuperOwner) public virtual onlySuperOwner {
        require(newSuperOwner != address(0), "Ownable: new super owner is the zero address");
        _transferSuperOwnership(newSuperOwner);
    }

    /**
     * @dev Grant ownership of the contract to an account (`newOwner`).
     * Can only be called by the current super owner.
     */
    function grantOwnership(address newOwner) public virtual onlySuperOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _grantOwnership(newOwner);
    }

    /**
     * @dev Revoke ownership of the contract to an account (`oldOwner`).
     * Can only be called by the current super owner.
     */
    function revokeOwnership(address oldOwner) public virtual onlySuperOwner {
        _revokeOwnership(oldOwner);
    }

    /**
     * @dev Transfers super ownership of the contract to a new account (`newSuperOwner`).
     * Internal function without access restriction.
     */
    function _transferSuperOwnership(address newSuperOwner) internal virtual {
        address oldSuperOwner = _superOwner;
        _superOwner = newSuperOwner;
        emit SuperOwnershipTransferred(oldSuperOwner, newSuperOwner);
    }

    /**
     * @dev Grant ownership of the contract to an account (`newOwner`).
     * Internal function without access restriction.
     */
    function _grantOwnership(address newOwner) internal virtual {
        require(!owners[newOwner], "Ownable: new owner is already owner");
        _owners.push(newOwner);
        owners[newOwner] = true;
        emit OwnershipChanged(newOwner, true);
    }

    /**
     * @dev Revoke ownership of the contract to an account (`oldOwner`).
     * Internal function without access restriction.
     */
    function _revokeOwnership(address oldOwner) internal virtual {
        require(owners[oldOwner], "Ownable: old owner is not owner");
        // remove address, put last element and pop
        for (uint i = 0; i < _owners.length; i++) {
            if (_owners[i] == oldOwner) {
                _owners[i] = _owners[_owners.length - 1];
                _owners.pop();
                break;
            }
        }
        owners[oldOwner] = false;
        emit OwnershipChanged(oldOwner, false);
    }


    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}