// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "sol.lib.binmaskflag/Binary.sol";
import "../../deploy/LibIntegrityCheck.sol";
import "./OpReadMemory.sol";
import "../../extern/LibExtern.sol";
import "../../run/LibStackPointer.sol";

/// Thrown when the length of results from an extern don't match what the operand
/// defines. This is bad because it implies our integrity check miscalculated the
/// stack which is undefined behaviour.
/// @param expected The length we expected based on the operand.
/// @param actual The length that was returned from the extern.
error BadExternResultsLength(uint256 expected, uint256 actual);

library OpExtern {
    using LibIntegrityCheck for IntegrityCheckState;
    using LibStackPointer for StackPointer;

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand operand_,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        uint256 inputs_ = Operand.unwrap(operand_) & MASK_5BIT;
        uint256 outputs_ = (Operand.unwrap(operand_) >> 5) & MASK_5BIT;
        uint256 offset_ = Operand.unwrap(operand_) >> 10;

        if (offset_ >= integrityCheckState_.constantsLength) {
            revert OutOfBoundsConstantsRead(
                integrityCheckState_.constantsLength,
                offset_
            );
        }

        return
            integrityCheckState_.push(
                integrityCheckState_.pop(stackTop_, inputs_),
                outputs_
            );
    }

    function intern(
        InterpreterState memory interpreterState_,
        Operand operand_,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        IInterpreterExternV1 interpreterExtern_;
        ExternDispatch externDispatch_;
        uint256 head_;
        uint256[] memory tail_;
        {
            uint256 inputs_ = Operand.unwrap(operand_) & MASK_5BIT;
            uint256 offset_ = (Operand.unwrap(operand_) >> 10);

            // Mirrors constant opcode.
            EncodedExternDispatch encodedDispatch_;
            assembly ("memory-safe") {
                encodedDispatch_ := mload(
                    add(mload(add(interpreterState_, 0x20)), mul(0x20, offset_))
                )
            }

            (interpreterExtern_, externDispatch_) = LibExtern.decode(
                encodedDispatch_
            );
            (head_, tail_) = stackTop_.list(inputs_);
            stackTop_ = stackTop_.down(inputs_).down().push(head_);
        }

        {
            uint256 outputs_ = (Operand.unwrap(operand_) >> 5) & MASK_5BIT;

            uint256[] memory results_ = interpreterExtern_.extern(
                externDispatch_,
                tail_
            );

            if (results_.length != outputs_) {
                revert BadExternResultsLength(outputs_, results_.length);
            }

            stackTop_ = stackTop_.push(results_);
        }

        return stackTop_;
    }
}