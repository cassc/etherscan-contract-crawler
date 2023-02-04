// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

/**
 * @dev Paxoswap modifications of original OpenZeppelin's {Ownable} implementation:
 * - bump `pragma solidity` (`^0.8.0` -> `^0.8.16`)
 * - adjust OpenZeppelin's {Context} import (use `library` implementation)
 * - shortify `require` messages (`Ownable:` -> `OW:` + others to avoid length warnings)
 * - extract {IOwnable} interface
 */

pragma solidity ^0.8.16;

import "./IOwnable.sol";
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
abstract contract Ownable is IOwnable, Context {
    address private _owner;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev See {IOwnable-owner}
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "OW: caller is not the owner");
    }

    /**
     * @dev See {IOwnable-renounceOwnership}
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev See {IOwnable-transferOwnership}
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "OW: new owner is zero address");
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
}