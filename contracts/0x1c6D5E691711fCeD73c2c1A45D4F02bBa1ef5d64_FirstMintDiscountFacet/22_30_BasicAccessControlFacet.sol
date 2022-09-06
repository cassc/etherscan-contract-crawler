// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./AccessControlLib.sol";
import {PausableLib} from "../Pausable/PausableLib.sol";

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
abstract contract BasicAccessControlFacet is Context {
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return AccessControlLib.accessControlStorage()._owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual {
        PausableLib.enforceUnpaused();
        AccessControlLib._enforceOwner();
        AccessControlLib._transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual {
        PausableLib.enforceUnpaused();
        AccessControlLib._enforceOwner();
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        AccessControlLib._transferOwnership(newOwner);
    }

    function grantOperator(address _operator) public virtual {
        PausableLib.enforceUnpaused();
        AccessControlLib._enforceOwner();

        AccessControlLib.grantRole(AccessControlLib.OPERATOR_ROLE, _operator);
    }

    function revokeOperator(address _operator) public virtual {
        PausableLib.enforceUnpaused();
        AccessControlLib._enforceOwner();
        AccessControlLib.revokeRole(AccessControlLib.OPERATOR_ROLE, _operator);
    }
}