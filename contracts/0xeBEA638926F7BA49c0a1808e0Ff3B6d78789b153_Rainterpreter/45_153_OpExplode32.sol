// SPDX-License-Identifier: CAL
pragma solidity =0.8.18;

import "../../run/LibStackPointer.sol";
import "sol.lib.memory/LibUint256Array.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";

/// @title OpExplode
/// @notice Opcode for exploding a single value into 8x 32 bit integers.
library OpExplode32 {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return
            integrityCheckState_.push(integrityCheckState_.pop(stackTop_), 8);
    }

    function run(
        InterpreterState memory,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        (StackPointer location_, uint256 i_) = stackTop_.pop();
        uint256 mask_ = uint256(type(uint32).max);
        return
            location_.push(
                i_ & mask_,
                (i_ >> 0x20) & mask_,
                (i_ >> 0x40) & mask_,
                (i_ >> 0x60) & mask_,
                (i_ >> 0x80) & mask_,
                (i_ >> 0xA0) & mask_,
                (i_ >> 0xC0) & mask_,
                (i_ >> 0xE0) & mask_
            );
    }
}