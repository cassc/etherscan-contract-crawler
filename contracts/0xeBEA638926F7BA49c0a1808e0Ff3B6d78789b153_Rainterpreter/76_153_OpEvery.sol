// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;
import "../../../run/LibStackPointer.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityCheck.sol";

/// @title OpEvery
/// @notice Opcode to compare the top N stack values.
library OpEvery {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand operand_,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        function(uint256[] memory) internal view returns (uint256) fn_;
        return
            integrityCheckState_.applyFn(
                stackTop_,
                fn_,
                Operand.unwrap(operand_)
            );
    }

    // EVERY
    // EVERY is either the first item if every item is nonzero, else 0.
    // operand_ is the length of items to check.
    function run(
        InterpreterState memory,
        Operand operand_,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        StackPointer bottom_ = stackTop_.down(Operand.unwrap(operand_));
        for (
            StackPointer i_ = bottom_;
            StackPointer.unwrap(i_) < StackPointer.unwrap(stackTop_);
            i_ = i_.up()
        ) {
            if (i_.peekUp() == 0) {
                return bottom_.push(0);
            }
        }
        return bottom_.up();
    }
}