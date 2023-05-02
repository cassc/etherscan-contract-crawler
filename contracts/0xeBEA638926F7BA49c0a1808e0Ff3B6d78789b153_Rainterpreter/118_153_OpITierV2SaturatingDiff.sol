// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../../tier/libraries/TierwiseCombine.sol";
import "../../run/LibStackPointer.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";

library OpSaturatingDiff {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return
            integrityCheckState_.applyFn(
                stackTop_,
                TierwiseCombine.saturatingSub
            );
    }

    // Stack the tierwise saturating subtraction of two reports.
    // If the older report is newer than newer report the result will
    // be `0`, else a tierwise diff in blocks will be obtained.
    // The older and newer report are taken from the stack.
    function run(
        InterpreterState memory,
        Operand,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFn(TierwiseCombine.saturatingSub);
    }
}