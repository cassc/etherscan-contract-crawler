//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../errors/Errors.sol";
import {CallerState, CallerContextStorage} from "../storage/CallerContextStorage.sol";
import {ExtendableState, ExtendableStorage} from "../storage/ExtendableStorage.sol";

/**
 *  ______  __  __  ______  ______  __   __  _____   ______  ______  __      ______    
 * /\  ___\/\_\_\_\/\__  _\/\  ___\/\ "-.\ \/\  __-./\  __ \/\  == \/\ \    /\  ___\
 * \ \  __\\/_/\_\/\/_/\ \/\ \  __\\ \ \-.  \ \ \/\ \ \  __ \ \  __<\ \ \___\ \  __\
 *  \ \_____\/\_\/\_\ \ \_\ \ \_____\ \_\\"\_\ \____-\ \_\ \_\ \_____\ \_____\ \_____\
 *   \/_____/\/_/\/_/  \/_/  \/_____/\/_/ \/_/\/____/ \/_/\/_/\/_____/\/_____/\/_____/
 *
 *  Core module for the Extendable framework
 *  
 *  Inherit this contract to make your contracts Extendable!
 *
 *  Your contract can perform ad-hoc addition or removal of functions
 *  which allows modularity, re-use, upgrade, and extension of your
 *  deployed contracts. You can make your contract immutable by removing
 *  the ability for it to be extended.
 *
 *  Constructor initialises owner-based permissioning to manage
 *  extending, where only the `owner` can extend the contract.
 *  
 *  You may change this constructor or use extension replacement to
 *  use a different permissioning pattern for your contract.
 *
 *  Requirements:
 *      - ExtendLogic contract must already be deployed
 */
contract Extendable {
    /**
     * @dev Contract constructor initialising the first extension `ExtendLogic`
     *      to allow the contract to be extended.
     *
     * This implementation assumes that the `ExtendLogic` being used also uses
     * an ownership pattern that only allows `owner` to extend the contract.
     * 
     * This constructor sets the owner of the contract and extends itself
     * using the ExtendLogic extension.
     *
     * To change owner or ownership mode, your contract must be extended with the
     * PermissioningLogic extension, giving it access to permissioning management.
     */
    constructor(address extendLogic) {
        // wrap main constructor logic in pre/post fallback hooks for callstack registration
        _beforeFallback();

        // extend extendable contract with the first extension: extend, using itself in low-level call
        (bool extendSuccess, ) = extendLogic.delegatecall(abi.encodeWithSignature("extend(address)", extendLogic));

        // check that initialisation tasks were successful
        require(extendSuccess, "failed to initialise extension");

        _afterFallback();
    }
    
    /**
     * @dev Delegates function calls to the specified `delegatee`.
     *
     * Performs a delegatecall to the `delegatee` with the incoming transaction data
     * as the input and returns the result. The transaction data passed also includes 
     * the function signature which determines what function is attempted to be called.
     * 
     * If the `delegatee` returns a ExtensionNotImplemented error, the `delegatee` is
     * an extension that does not implement the function to be called.
     *
     * Otherwise, the function execution fails/succeeds as determined by the function 
     * logic and returns as such.
     */
    function _delegate(address delegatee) internal virtual returns(bool) {
        _beforeFallback();
        
        bytes memory out;
        (bool success, bytes memory result) = delegatee.delegatecall(msg.data);

        _afterFallback();

        // copy all returndata to `out` once instead of duplicating copy for each conditional branch
        assembly {
            returndatacopy(out, 0, returndatasize())
        }

        // if the delegatecall execution did not succeed
        if (!success) {
            // check if failure was due to an ExtensionNotImplemented error
            if (Errors.catchCustomError(result, ExtensionNotImplemented.selector)) {
                // cleanly return false if error is caught
                return false;
            } else {
                // otherwise revert, passing in copied full returndata
                assembly {
                    revert(out, returndatasize())
                }
            }
        } else {
            // otherwise end execution and return the copied full returndata
            assembly {
                return(out, returndatasize())
            }
        }
    }
    
    /**
     * @dev Internal fallback function logic that attempts to delegate execution
     *      to extension contracts
     *
     * Initially attempts to locate an interfaceId match with a function selector
     * which are extensions that house single functions (singleton extensions)
     *
     * If no implementations are found that match the requested function signature,
     * returns ExtensionNotImplemented error
     */
    function _fallback() internal virtual {
        ExtendableState storage state = ExtendableStorage._getState();

        // if an extension exists that matches in the functionsig
        if (state.extensionContracts[msg.sig] != address(0x0)) {
            // call it
            _delegate(state.extensionContracts[msg.sig]);
        } else {                                                 
            revert ExtensionNotImplemented();
        }
    }

    /**
     * @dev Default fallback function to catch unrecognised selectors.
     *
     * Used in order to perform extension lookups by _fallback().
     *
     * Core fallback logic sandwiched between caller context work.
     */
    fallback() external payable virtual {
        _fallback();
    }
    
    /**
     * @dev Payable fallback function to catch unrecognised selectors with ETH payments.
     *
     * Used in order to perform extension lookups by _fallback().
     */
    receive() external payable virtual {
        _fallback();
    }
    
    /**
     * @dev Virtual hook that is called before _fallback().
     */
    function _beforeFallback() internal virtual {
        CallerState storage state = CallerContextStorage._getState();
        state.callerStack.push(msg.sender);
    }
    
    /**
     * @dev Virtual hook that is called after _fallback().
     */
    function _afterFallback() internal virtual {
        CallerState storage state = CallerContextStorage._getState();
        state.callerStack.pop();
    }
}