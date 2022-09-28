// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import {State} from "../../RainVM.sol";
import "../../../math/SaturatingMath.sol";

/// @dev Opcode for addition.
uint256 constant OPCODE_ADD = 0;
/// @dev Opcode for saturating addition.
uint256 constant OPCODE_SATURATING_ADD = 1;
/// @dev Opcode for subtraction.
uint256 constant OPCODE_SUB = 2;
/// @dev Opcode for saturating subtraction.
uint256 constant OPCODE_SATURATING_SUB = 3;
/// @dev Opcode for multiplication.
uint256 constant OPCODE_MUL = 4;
/// @dev Opcode for saturating multiplication.
uint256 constant OPCODE_SATURATING_MUL = 5;
/// @dev Opcode for division.
uint256 constant OPCODE_DIV = 6;
/// @dev Opcode for modulo.
uint256 constant OPCODE_MOD = 7;
/// @dev Opcode for exponentiation.
uint256 constant OPCODE_EXP = 8;
/// @dev Opcode for minimum.
uint256 constant OPCODE_MIN = 9;
/// @dev Opcode for maximum.
uint256 constant OPCODE_MAX = 10;
/// @dev Number of provided opcodes for `MathOps`.
uint256 constant MATH_OPS_LENGTH = 11;

/// @title MathOps
/// @notice RainVM opcode pack to perform basic checked math operations.
/// Underflow and overflow will error as per default solidity behaviour.
/// SaturatingMath opcodes are provided as "core" math because the VM has no
/// ability to lazily execute code, which means that overflows cannot be
/// guarded with conditional logic. Saturation is a quick and dirty solution to
/// overflow that is valid in many situations.
library MathOps {
    using SaturatingMath for uint256;

    function applyOp(
        State memory state_,
        uint256 opcode_,
        uint256 operand_
    ) internal pure {
        require(opcode_ < MATH_OPS_LENGTH, "MAX_OPCODE");
        uint256 baseIndex_;
        uint256 top_;
        unchecked {
            baseIndex_ = state_.stackIndex - operand_;
            top_ = state_.stackIndex - 1;
        }
        uint256 cursor_ = baseIndex_;
        uint256 accumulator_ = state_.stack[cursor_];

        // Addition.
        if (opcode_ == OPCODE_ADD) {
            while (cursor_ < top_) {
                unchecked {
                    cursor_++;
                }
                accumulator_ += state_.stack[cursor_];
            }
        }
        // Saturating addition.
        else if (opcode_ == OPCODE_SATURATING_ADD) {
            unchecked {
                while (cursor_ < top_ && accumulator_ < type(uint256).max) {
                    cursor_++;
                    accumulator_ = accumulator_.saturatingAdd(
                        state_.stack[cursor_]
                    );
                }
            }
        }
        // Subtraction.
        else if (opcode_ == OPCODE_SUB) {
            while (cursor_ < top_) {
                unchecked {
                    cursor_++;
                }
                accumulator_ -= state_.stack[cursor_];
            }
        }
        // Saturating subtraction.
        else if (opcode_ == OPCODE_SATURATING_SUB) {
            unchecked {
                while (cursor_ < top_ && 0 < accumulator_) {
                    cursor_++;
                    accumulator_ = accumulator_.saturatingSub(
                        state_.stack[cursor_]
                    );
                }
            }
        }
        // Multiplication.
        // Slither false positive here complaining about dividing before
        // multiplying but both are mututally exclusive according to `opcode_`.
        else if (opcode_ == OPCODE_MUL) {
            while (cursor_ < top_) {
                unchecked {
                    cursor_++;
                }
                accumulator_ *= state_.stack[cursor_];
            }
        }
        // Saturating multiplication.
        else if (opcode_ == OPCODE_SATURATING_MUL) {
            unchecked {
                while (cursor_ < top_ && accumulator_ < type(uint256).max) {
                    cursor_++;
                    accumulator_ = accumulator_.saturatingMul(
                        state_.stack[cursor_]
                    );
                }
            }
        }
        // Division.
        else if (opcode_ == OPCODE_DIV) {
            while (cursor_ < top_) {
                unchecked {
                    cursor_++;
                }
                accumulator_ /= state_.stack[cursor_];
            }
        }
        // Modulo.
        else if (opcode_ == OPCODE_MOD) {
            while (cursor_ < top_) {
                unchecked {
                    cursor_++;
                }
                accumulator_ %= state_.stack[cursor_];
            }
        }
        // Exponentiation.
        else if (opcode_ == OPCODE_EXP) {
            while (cursor_ < top_) {
                unchecked {
                    cursor_++;
                }
                accumulator_ = accumulator_**state_.stack[cursor_];
            }
        }
        // Minimum.
        else if (opcode_ == OPCODE_MIN) {
            uint256 item_;
            while (cursor_ < top_) {
                unchecked {
                    cursor_++;
                }
                item_ = state_.stack[cursor_];
                if (item_ < accumulator_) {
                    accumulator_ = item_;
                }
            }
        }
        // Maximum.
        else if (opcode_ == OPCODE_MAX) {
            uint256 item_;
            while (cursor_ < top_) {
                unchecked {
                    cursor_++;
                }
                item_ = state_.stack[cursor_];
                if (item_ > accumulator_) {
                    accumulator_ = item_;
                }
            }
        }

        unchecked {
            state_.stack[baseIndex_] = accumulator_;
            state_.stackIndex = baseIndex_ + 1;
        }
    }
}