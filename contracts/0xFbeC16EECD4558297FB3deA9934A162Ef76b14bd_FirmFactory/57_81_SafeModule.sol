// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FirmBase} from "./FirmBase.sol";
import {ISafe} from "./interfaces/ISafe.sol";

/**
 * @title SafeModule
 * @dev More minimal implementation of Safe's Module.sol without an owner
 * and using unstructured storage
 * @dev Note that this contract doesn't have an initializer and SafeState
 * must be set explicly if desired, but defaults to being unset
 */
abstract contract SafeModule is FirmBase {
    error BadExecutionContext();

    // Sometimes it makes sense to have some code from the module ran on the Safe context
    // via a DelegateCall operation.
    // Since the functions the Safe can enter through have to be external,
    // we need to ensure that we aren't in the context of the module (or it's implementation)
    // for extra security
    // NOTE: this would break if Safe were to start using the EIP-1967 implementation slot
    // as it is how foreign context detection works
    modifier onlyForeignContext() {
        if (!_isForeignContext()) {
            revert BadExecutionContext();
        }
        _;
    }

    /**
     * @dev Executes a transaction through the target intended to be executed by the avatar
     * @param to Address being called
     * @param value Ether value being sent
     * @param data Calldata
     * @param operation Operation type of transaction: 0 = call, 1 = delegatecall
     */
    function _moduleExec(address to, uint256 value, bytes memory data, ISafe.Operation operation)
        internal
        returns (bool success)
    {
        return safe().execTransactionFromModule(to, value, data, operation);
    }

    /**
     * @dev Executes a transaction through the target intended to be executed by the avatar
     * and returns the call status and the return data of the call
     * @param to Address being called
     * @param value Ether value being sent
     * @param data Calldata
     * @param operation Operation type of transaction: 0 = call, 1 = delegatecall
     */
    function _moduleExecAndReturnData(address to, uint256 value, bytes memory data, ISafe.Operation operation)
        internal
        returns (bool success, bytes memory returnData)
    {
        return safe().execTransactionFromModuleReturnData(to, value, data, operation);
    }

    function _moduleExecDelegateCallToSelf(bytes memory data) internal returns (bool success) {
        return _moduleExec(address(_implementation()), 0, data, ISafe.Operation.DelegateCall);
    }
}