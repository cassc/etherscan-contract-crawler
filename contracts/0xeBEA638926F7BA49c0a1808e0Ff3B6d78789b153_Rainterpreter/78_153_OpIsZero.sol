// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;
import "../../../run/LibStackPointer.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityCheck.sol";

/// @title OpIsZero
/// @notice Opcode for checking if the stack top is zero.
library OpIsZero {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(uint256 a_) internal pure returns (uint256 b_) {
        assembly ("memory-safe") {
            b_ := iszero(a_)
        }
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.applyFn(stackTop_, f);
    }

    function run(
        InterpreterState memory,
        Operand,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFn(f);
    }
}