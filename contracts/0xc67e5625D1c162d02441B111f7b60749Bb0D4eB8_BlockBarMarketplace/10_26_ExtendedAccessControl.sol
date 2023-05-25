// SPDX-License-Identifier:  AGPL-3.0-or-later
pragma solidity 0.8.18;

import {Pausable} from "Pausable.sol";
import {AccessControl} from "AccessControl.sol";
import {ReentrancyGuard} from "ReentrancyGuard.sol";
import {IExtendedAccessControl} from "IExtendedAccessControl.sol";

/**
* @title ExtendedAccessControl
* @author aarora
* @notice ExtendedAccessControl inherits AccessControl, Pausable, ReentrancyGuard to add control and security layers.
          Additionally, the contract defines roles for fine grain access control.
          Inheriting this contract enables ability to pause, unpause the contract.
          The DEFAULT_ADMIN_ROLE has the ability to drain the marketplace for dust collection.
*/
contract ExtendedAccessControl is IExtendedAccessControl, AccessControl, Pausable, ReentrancyGuard {

    // Declare custom role.
    // PAUSER ROLE has ability to pause/unpause the contract
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    address internal _owner;

    constructor(){
        _owner = msg.sender;
        // DEFAULT ADMIN ROLE has the ability to assign PAUSER ROLE
        // set contract caller to have the following roles.
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
    * @notice get the owner of this contract
    *
    **/
    function getOwner() external view returns(address owner) {
        return _owner;
    }

    /**
     * @notice Pause contract modification activity. Only Pauser role can call this function.
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @notice Unpause contract modification activity. Only Pauser role can call this function.
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _revokeRole(bytes32 role, address account) internal virtual override {
        require(role != DEFAULT_ADMIN_ROLE, "Cannot revoke default admin role");
        super._revokeRole(role, account);
    }
}