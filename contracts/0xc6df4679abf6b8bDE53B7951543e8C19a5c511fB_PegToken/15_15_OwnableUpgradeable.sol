// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin-contracts-upgradeable/contracts/utils/ContextUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {pushOwnership} and {pullOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;
    address private _proposedOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed proposedOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed proposedOwner);
    event OwnershipProposalCancelled(address indexed currentOwner, address indexed proposedOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _owner = _msgSender();
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the proposed owner.
     */
    function proposedOwner() public view virtual returns (address) {
        return _proposedOwner;
    }

    /**
     * @dev Push ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function pushOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _proposedOwner = newOwner;
        emit OwnershipPushed(_owner, newOwner);
    }

    /**
     * @dev Cancel proposed ownership transfer of the contract.
     * Can only be called by the current owner.
     */
    function cancelProposedOwnership() public virtual onlyOwner {
        address oldProposedOwner = _proposedOwner;
        _proposedOwner = address(0);
        emit OwnershipProposalCancelled(_owner, oldProposedOwner);
    }

    /**
     * @dev Pull ownership of the contract to a proposed owner.
     * Can only be called by the proposed owner.
     */
    function pullOwnership() public virtual {
        require(_proposedOwner == _msgSender(), "Ownable: caller is not the proposed owner");
        address oldOwner = _owner;
        _owner = _proposedOwner;
        _proposedOwner = address(0);
        emit OwnershipPulled(oldOwner, _msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}