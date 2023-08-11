// SPDX-License-Identifier: CAL
pragma solidity =0.8.18;

import "sol.lib.memory/LibPointer.sol";
import "sol.lib.memory/LibBytes.sol";

import "../interface/IExtrospectBytecodeV2.sol";
import "../interface/IExtrospectInterpreterV1.sol";
import "../interface/IExtrospectERC1167ProxyV1.sol";

import "../lib/LibExtrospectBytecode.sol";
import "../lib/LibExtrospectERC1167Proxy.sol";

/// @title Extrospection
/// @notice Implements all extrospection interfaces.
contract Extrospection is IExtrospectBytecodeV2, IExtrospectInterpreterV1, IExtrospectERC1167ProxyV1 {
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

    /// @inheritdoc IExtrospectERC1167ProxyV1
    function isERC1167Proxy(address account) external view returns (bool result, address implementationAddress) {
        // Slither false positive. We do use the return value... by returning it.
        //slither-disable-next-line unused-return
        return LibExtrospectERC1167Proxy.isERC1167Proxy(account.code);
    }
}