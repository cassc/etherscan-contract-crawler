// SPDX-License-Identifier: CAL
pragma solidity =0.8.18;

import "sol.lib.memory/LibPointer.sol";
import "sol.lib.memory/LibBytes.sol";

import "./LibExtrospectBytecode.sol";
import "./IExtrospectBytecodeV2.sol";
import "./IExtrospectInterpreterV1.sol";

/// @title Extrospection
/// @notice Implements all extrospection interfaces.
contract Extrospection is IExtrospectBytecodeV2, IExtrospectInterpreterV1 {
    using LibBytes for bytes;

    /// @inheritdoc IExtrospectBytecodeV2
    function bytecode(address account) external view returns (bytes memory) {
        return account.code;
    }

    /// @inheritdoc IExtrospectBytecodeV2
    function bytecodeHash(address account) external view returns (bytes32) {
        return account.codehash;
    }

    /// @inheritdoc IExtrospectBytecodeV2
    function scanEVMOpcodesPresentInAccount(address account) public view returns (uint256) {
        return LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(account.code);
    }

    /// @inheritdoc IExtrospectBytecodeV2
    function scanEVMOpcodesReachableInAccount(address account) public view returns (uint256) {
        return LibExtrospectBytecode.scanEVMOpcodesReachableInBytecode(account.code);
    }

    /// @inheritdoc IExtrospectInterpreterV1
    function scanOnlyAllowedInterpreterEVMOpcodes(address interpreter) external view returns (bool) {
        return scanEVMOpcodesReachableInAccount(interpreter) & INTERPRETER_DISALLOWED_OPS == 0;
    }
}