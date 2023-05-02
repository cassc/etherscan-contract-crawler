// SPDX-License-Identifier: CAL
pragma solidity =0.8.18;

import "../../run/LibStackPointer.sol";
import "sol.lib.memory/LibUint256Array.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";

/// @title OpAdd
/// @notice Opcode for adding N numbers with error on overflow.
library OpAdd {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    /// Addition with implied overflow checks from the Solidity 0.8.x compiler.
    function f(uint256 a_, uint256 b_) internal pure returns (uint256) {
        return a_ + b_;
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