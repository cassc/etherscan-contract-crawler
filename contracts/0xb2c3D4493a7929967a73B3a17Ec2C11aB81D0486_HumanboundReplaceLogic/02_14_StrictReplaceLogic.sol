//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../Extension.sol";
import "./IReplaceLogic.sol";
import "../extend/IExtendLogic.sol";
import "../retract/IRetractLogic.sol";
import {ExtendableState, ExtendableStorage} from "../../storage/ExtendableStorage.sol";
import {RoleState, Permissions} from "../../storage/PermissionStorage.sol";

// Requires the Extendable to have been extended with both ExtendLogic and RetractLogic
// Only allows replacement of extensions that share the exact same interface
// Safest ReplaceLogic extension
contract StrictReplaceLogic is ReplaceExtension {
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
     * @dev see {IReplaceLogic-replace} Replaces an old extension with a new extension that matches the old interface.
     *
     * Uses RetractLogic to remove old and ExtendLogic to add new.
     *
     * Strictly only allows replacement of extensions with new implementations of the same interface.
    */
    function replace(address oldExtension, address newExtension) public override virtual onlyOwner {
        require(newExtension.code.length > 0, "Replace: new extend address is not a contract");

        IExtension old = IExtension(payable(oldExtension));
        IExtension newEx = IExtension(payable(newExtension));

        Interface[] memory oldInterfaces = old.getInterface();
        Interface[] memory newInterfaces = newEx.getInterface();

        // require the interfaceIds implemented by the old extension is equal to the new one
        bytes4 oldFullInterface = oldInterfaces[0].interfaceId;
        bytes4 newFullInterface = newInterfaces[0].interfaceId;

        for (uint256 i = 1; i < oldInterfaces.length; i++) {
            oldFullInterface = oldFullInterface ^ oldInterfaces[i].interfaceId;
        }

        for (uint256 i = 1; i < newInterfaces.length; i++) {
            newFullInterface = newFullInterface ^ newInterfaces[i].interfaceId;
        }
        
        require(
            newFullInterface == oldFullInterface, 
            "Replace: interface of new does not match old, please only use identical interfaces"
        );

        // Initialise both prior to state change for safety
        IRetractLogic retractLogic = IRetractLogic(payable(address(this)));
        IExtendLogic extendLogic = IExtendLogic(payable(address(this)));

        // remove old extension by using current retract logic instead of implementing conflicting logic
        retractLogic.retract(oldExtension);

        // attempt to extend with new extension
        try extendLogic.extend(newExtension) {
            // success
        }  catch Error(string memory reason) {
            revert(reason);
        } catch (bytes memory err) { // if it fails, check if this is due to extend being replaced
            if (Errors.catchCustomError(err, ExtensionNotImplemented.selector)) { // make sure this is a not implemented error due to removal of Extend
                // use raw delegate call to re-extend the extension because we have just removed the Extend function
                (bool extendSuccess, ) = newExtension.delegatecall(abi.encodeWithSignature("extend(address)", newExtension));
                require(extendSuccess, "Replace: failed to replace extend");
            } else {
                uint errLen = err.length;
                assembly {
                    revert(err, errLen)
                }
            }
        }

        emit Replaced(oldExtension, newExtension);
    }
}