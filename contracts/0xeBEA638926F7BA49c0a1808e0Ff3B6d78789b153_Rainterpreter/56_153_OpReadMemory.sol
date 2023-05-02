// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../../run/LibStackPointer.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";
import "sol.lib.binmaskflag/Binary.sol";
import {MathUpgradeable as Math} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

/// Thrown when a stack read index is outside the current stack top.
error OutOfBoundsStackRead(uint256 stackTopIndex, uint256 stackRead);

/// Thrown when a constant read index is outside the constants array.
error OutOfBoundsConstantsRead(uint256 constantsLength, uint256 constantsRead);

/// @dev Read a value from the stack.
uint256 constant OPERAND_MEMORY_TYPE_STACK = 0;
/// @dev Read a value from the constants.
uint256 constant OPERAND_MEMORY_TYPE_CONSTANT = 1;

/// @title OpReadMemory
/// @notice Opcode for stacking from the interpreter state in memory. This can
/// either be copying values from anywhere in the stack or from the constants
/// array by index.
library OpReadMemory {
    using LibStackPointer for StackPointer;
    using LibInterpreterState for InterpreterState;
    using LibIntegrityCheck for IntegrityCheckState;
    using Math for uint256;

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand operand_,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        uint256 type_ = Operand.unwrap(operand_) & MASK_1BIT;
        uint256 offset_ = Operand.unwrap(operand_) >> 1;
        if (type_ == OPERAND_MEMORY_TYPE_STACK) {
            uint256 stackTopIndex_ = integrityCheckState_.stackBottom.toIndex(
                stackTop_
            );
            if (offset_ >= stackTopIndex_) {
                revert OutOfBoundsStackRead(stackTopIndex_, offset_);
            }

            // Ensure that highwater is moved past any stack item that we
            // read so that copied values cannot later be consumed.
            integrityCheckState_.stackHighwater = StackPointer.wrap(
                StackPointer.unwrap(integrityCheckState_.stackHighwater).max(
                    StackPointer.unwrap(
                        integrityCheckState_.stackBottom.up(offset_)
                    )
                )
            );
        } else {
            if (offset_ >= integrityCheckState_.constantsLength) {
                revert OutOfBoundsConstantsRead(
                    integrityCheckState_.constantsLength,
                    offset_
                );
            }
        }
        return integrityCheckState_.push(stackTop_);
    }

    function run(
        InterpreterState memory state_,
        Operand operand_,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        unchecked {
            uint256 type_ = Operand.unwrap(operand_) & MASK_1BIT;
            uint256 offset_ = Operand.unwrap(operand_) >> 1;
            assembly ("memory-safe") {
                mstore(
                    stackTop_,
                    mload(
                        add(
                            mload(add(state_, mul(0x20, type_))),
                            mul(0x20, offset_)
                        )
                    )
                )
            }
            return StackPointer.wrap(StackPointer.unwrap(stackTop_) + 0x20);
        }
    }
}