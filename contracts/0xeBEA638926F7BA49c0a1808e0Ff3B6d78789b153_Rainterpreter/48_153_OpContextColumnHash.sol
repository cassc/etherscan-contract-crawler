// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../deploy/LibIntegrityCheck.sol";
import "../../run/LibInterpreterState.sol";

/// @title OpContextColumnHash
/// @notice Hashes a single context column. Useful for snapshotting values
/// provided by users, whether signed by a third party or provided by the caller.
/// More gas efficient than individually snapshotting each context row and
/// handles dynamic length columns without an expensive fold operation.
library OpContextColumnHash {
    using LibIntegrityCheck for IntegrityCheckState;
    using LibStackPointer for StackPointer;

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        // Note that a expression with context can error at runtime due to OOB
        // reads that we don't know about here.
        return integrityCheckState_.push(stackTop_);
    }

    function run(
        InterpreterState memory state_,
        Operand operand_,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return
            stackTop_.push(
                uint256(
                    keccak256(
                        // Using encodePacked here instead of encode so that we
                        // really only hash the values of the column and not the
                        // leading length bytes.
                        // Typically we would NOT use encodePacked for a dynamic
                        // type due to the potential for accidentally introducing
                        // hash collisions between multiple adjacent dynamic
                        // types, e.g. "ab" + "c" and "a" + "bc". In this case we
                        // are producing hashes over a single list at a time, and
                        // hash("ab") + hash("c") and hash("a") + hash("bc") do
                        // not collide, so there is no ambiguity even with many
                        // lists being hashed this way.
                        abi.encodePacked(
                            state_.context[Operand.unwrap(operand_)]
                        )
                    )
                )
            );
    }
}