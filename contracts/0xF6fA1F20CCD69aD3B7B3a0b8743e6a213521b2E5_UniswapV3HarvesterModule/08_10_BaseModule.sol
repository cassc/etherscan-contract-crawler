// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "IGnosisSafe.sol";

contract BaseModule {
    ////////////////////////////////////////////////////////////////////////////
    // ERRORS
    ////////////////////////////////////////////////////////////////////////////

    error ExecutionFailure(address to, bytes data, uint256 timestamp);

    ////////////////////////////////////////////////////////////////////////////
    // INTERNAL
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Allows executing specific calldata into an address thru a gnosis-safe, which have enable this contract as module.
    /// @param to Contract address where we will execute the calldata.
    /// @param data Calldata to be executed within the boundaries of the `allowedFunctions`.
    function _checkTransactionAndExecute(IGnosisSafe safe, address to, bytes memory data) internal {
        if (data.length >= 4) {
            bool success = safe.execTransactionFromModule(to, 0, data, IGnosisSafe.Operation.Call);
            if (!success) revert ExecutionFailure(to, data, block.timestamp);
        }
    }

    /// @notice Allows executing specific calldata into an address thru a gnosis-safe, which have enable this contract as module.
    /// @param to Contract address where we will execute the calldata.
    /// @param data Calldata to be executed within the boundaries of the `allowedFunctions`.
    /// @return bytes data containing the return data from the method in `to` with the payload `data`
    function _checkTransactionAndExecuteReturningData(IGnosisSafe safe, address to, bytes memory data)
        internal
        returns (bytes memory)
    {
        if (data.length >= 4) {
            (bool success, bytes memory returnData) =
                safe.execTransactionFromModuleReturnData(to, 0, data, IGnosisSafe.Operation.Call);
            if (!success) revert ExecutionFailure(to, data, block.timestamp);
            return returnData;
        }
    }
}