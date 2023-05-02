// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../run/LibStackPointer.sol";
import "sol.lib.memory/LibUint256Array.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";

/// @title OpEnsure
/// @notice Opcode for requiring some truthy values.
library OpEnsure {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(uint256 a_) internal pure {
        assembly ("memory-safe") {
            if iszero(a_) {
                revert(0, 0)
            }
        }
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand operand_,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return
            integrityCheckState_.applyFnN(
                stackTop_,
                f,
                Operand.unwrap(operand_)
            );
    }

    function run(
        InterpreterState memory,
        Operand operand_,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFnN(f, Operand.unwrap(operand_));
    }
}