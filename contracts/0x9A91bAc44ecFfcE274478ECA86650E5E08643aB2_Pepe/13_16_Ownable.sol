// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an pepe) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the pepe account will be the one that deploys the contract. This
 * can later be changed with {transferPepeship}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlypepe`, which can be applied to your functions to restrict their use to
 * the pepe.
 */
abstract contract Ownable  {
    address private _pepe;

    event OwnershipTransferred(address indexed previouspepe, address indexed newpepe);

    /**
     * @dev Initializes the contract setting the deployer as the initial pepe.
     */
    constructor() {
        _transferPepeship(msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the pepe.
     */
    modifier onlyPepe() {
        _checkPepe();
        _;
    }

    /**
     * @dev Returns the address of the current pepe.
     */
    function pepe() public view virtual returns (address) {
        return _pepe;
    }

    /**
     * @dev Throws if the sender is not the pepe.
     */
    function _checkPepe() internal view virtual {
        require(pepe() == msg.sender, "Ownable: peeeepeepepepe");
    }

    /**
     * @dev Leaves the contract without pepe. It will not be possible to call
     * `onlypepe` functions. Can only be called by the current pepe.
     *
     * NOTE: Renouncing pepeship will leave the contract without an pepe,
     * thereby disabling any functionality that is only available to the pepe.
     */
    function renouncePepeship() public virtual onlyPepe {
        _transferPepeship(address(0));
    }

    /**
     * @dev Transfers pepeship of the contract to a new account (`newpepe`).
     * Can only be called by the current pepe.
     */
    function transferPepeship(address newpepe) public virtual onlyPepe {
        require(newpepe != address(0), "Ownable: new pepe is the zero address");
        _transferPepeship(newpepe);
    }

    /**
     * @dev Transfers pepeship of the contract to a new account (`newpepe`).
     * Internal function without access restriction.
     */
    function _transferPepeship(address newpepe) internal virtual {
        address oldpepe = _pepe;
        _pepe = newpepe;
        emit OwnershipTransferred(oldpepe, newpepe);
    }
}