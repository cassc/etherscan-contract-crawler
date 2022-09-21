// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import {State} from "../../RainVM.sol";
import "../../../math/FixedPointMath.sol";

/// @dev Opcode for multiplication.
uint256 constant OPCODE_SCALE18_MUL = 0;
/// @dev Opcode for division.
uint256 constant OPCODE_SCALE18_DIV = 1;
/// @dev Opcode to rescale some fixed point number to 18 OOMs in situ.
uint256 constant OPCODE_SCALE18 = 2;
/// @dev Opcode to rescale an 18 OOMs fixed point number to scale N.
uint256 constant OPCODE_SCALEN = 3;
/// @dev Opcode to rescale an arbitrary fixed point number by some OOMs.
uint256 constant OPCODE_SCALE_BY = 4;
/// @dev Opcode for stacking the definition of one.
uint256 constant OPCODE_ONE = 5;
/// @dev Opcode for stacking number of fixed point decimals used.
uint256 constant OPCODE_DECIMALS = 6;
/// @dev Number of provided opcodes for `FixedPointMathOps`.
uint256 constant FIXED_POINT_MATH_OPS_LENGTH = 7;

/// @title FixedPointMathOps
/// @notice RainVM opcode pack to perform basic checked math operations.
/// Underflow and overflow will error as per default solidity behaviour.
library FixedPointMathOps {
    using FixedPointMath for uint256;

    function applyOp(
        State memory state_,
        uint256 opcode_,
        uint256 operand_
    ) internal pure {
        unchecked {
            require(opcode_ < FIXED_POINT_MATH_OPS_LENGTH, "MAX_OPCODE");

            if (opcode_ < OPCODE_SCALE18) {
                uint256 baseIndex_ = state_.stackIndex - 2;
                if (opcode_ == OPCODE_SCALE18_MUL) {
                    state_.stack[baseIndex_] =
                        state_.stack[baseIndex_].scale18(operand_) *
                        state_.stack[baseIndex_ + 1];
                } else if (opcode_ == OPCODE_SCALE18_DIV) {
                    state_.stack[baseIndex_] =
                        state_.stack[baseIndex_].scale18(operand_) /
                        state_.stack[baseIndex_ + 1];
                }
                state_.stackIndex--;
            } else if (opcode_ < OPCODE_ONE) {
                uint256 baseIndex_ = state_.stackIndex - 1;
                if (opcode_ == OPCODE_SCALE18) {
                    state_.stack[baseIndex_] = state_.stack[baseIndex_].scale18(
                        operand_
                    );
                } else if (opcode_ == OPCODE_SCALEN) {
                    state_.stack[baseIndex_] = state_.stack[baseIndex_].scaleN(
                        operand_
                    );
                } else if (opcode_ == OPCODE_SCALE_BY) {
                    state_.stack[baseIndex_] = state_.stack[baseIndex_].scaleBy(
                        int8(uint8(operand_))
                    );
                }
            } else {
                if (opcode_ == OPCODE_ONE) {
                    state_.stack[state_.stackIndex] = FP_ONE;
                    state_.stackIndex++;
                } else if (opcode_ == OPCODE_DECIMALS) {
                    state_.stack[state_.stackIndex] = FP_DECIMALS;
                    state_.stackIndex++;
                }
            }
        }
    }
}