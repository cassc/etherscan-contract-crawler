// SPDX-License-Identifier: CAL
pragma solidity =0.8.18;

import "../../run/LibStackPointer.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";

/// @title OpMax
/// @notice Opcode to stack the maximum of N numbers.
library OpMax {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(uint256 a_, uint256 b_) internal pure returns (uint256) {
        return a_ > b_ ? a_ : b_;
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
    ) internal view returns (StackPointer stackTopAfter_) {
        return stackTop_.applyFnN(f, Operand.unwrap(operand_));
    }
}