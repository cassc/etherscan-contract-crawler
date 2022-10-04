//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../Extension.sol";
import "./IPermissioningLogic.sol";
import {RoleState, Permissions} from "../../storage/PermissionStorage.sol";

/**
 * @dev Reference implementation for PermissioningLogic which defines the logic to control
 *      and define ownership of contracts
 *
 * Records address as `owner` in the PermissionStorage module. Modifications and access to 
 * the module affect the state wherever it is accessed by Extensions and can be read/written
 * from/to by other attached extensions.
 *
 * Currently used by the ExtendLogic reference implementation to restrict extend permissions
 * to only `owner`. Uses a common function from the storage library `_onlyOwner()` as a
 * modifier replacement. Can be wrapped in a modifier if preferred.
*/
contract PermissioningLogic is PermissioningExtension {
    /**
     * @dev see {Extension-constructor} for constructor
    */

    /**
     * @dev modifier that restricts caller of a function to only the most recent caller if they are `owner`
    */
    modifier onlyOwner virtual {
        address owner = Permissions._getState().owner;
        require(_lastCaller() == owner, "unauthorised");
        _;
    }

    /**
     * @dev see {IPermissioningLogic-init}
    */
    function init() override public virtual {
        RoleState storage state = Permissions._getState();
        require(state.owner == address(0x0), "PermissioningLogic: already initialised"); // make sure owner has yet to be set for delegator
        state.owner = _lastCaller();

        emit OwnerUpdated(_lastCaller());
    }

    /**
     * @dev see {IPermissioningLogic-updateOwner}
    */
    function updateOwner(address newOwner) override public onlyOwner virtual {
        require(newOwner != address(0x0), "new owner cannot be the zero address");
        RoleState storage state = Permissions._getState();
        state.owner = newOwner;

        emit OwnerUpdated(newOwner);
    }

    /**
     * @dev see {IPermissioningLogic-renounceOwnership}
    */
    function renounceOwnership() override public onlyOwner virtual {
        address NULL_ADDRESS = 0x000000000000000000000000000000000000dEaD;
        RoleState storage state = Permissions._getState();
        state.owner = NULL_ADDRESS;

        emit OwnerUpdated(NULL_ADDRESS);
    }

    /**
     * @dev see {IPermissioningLogic-getOwner}
    */
    function getOwner() override public virtual view returns(address) {
        RoleState storage state = Permissions._getState();
        return(state.owner);
    }
}