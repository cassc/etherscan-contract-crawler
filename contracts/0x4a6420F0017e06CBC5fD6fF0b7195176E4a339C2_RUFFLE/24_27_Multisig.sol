// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (a multisig) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the multisig account will be the one that deploys the contract. This
 * can later be changed with {transferMultisig}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyMultisig`, which can be applied to your functions to restrict their use to
 * the multisig.
 */
abstract contract Multisig is Context {
    address private _multisig;

    event MultisigTransferred(
        address indexed previousMultisig,
        address indexed newMultisig
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial multisig.
     */
    constructor() {
        _transferMultisig(_msgSender());
    }

    /**
     * @dev Returns the address of the current multisig.
     */
    function multisig() public view virtual returns (address) {
        return _multisig;
    }

    /**
     * @dev Throws if called by any account other than the multisig.
     */
    modifier onlyMultisig() {
        require(
            multisig() == _msgSender(),
            "Multisig: caller is not the multisig"
        );
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newMultisig`).
     * Can only be called by the current multisig.
     */
    function transferMultisig(address newMultisig) public virtual onlyMultisig {
        require(
            newMultisig != address(0),
            "Multisig: new multisig is the zero address"
        );
        _transferMultisig(newMultisig);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newMultisig`).
     * Internal function without access restriction.
     */
    function _transferMultisig(address newMultisig) internal virtual {
        address oldMultisig = _multisig;
        _multisig = newMultisig;
        emit MultisigTransferred(oldMultisig, newMultisig);
    }
}