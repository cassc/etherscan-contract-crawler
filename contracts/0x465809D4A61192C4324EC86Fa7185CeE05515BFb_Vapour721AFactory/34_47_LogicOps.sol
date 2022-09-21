// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import {State} from "../../RainVM.sol";

/// @dev Number of provided opcodes for `LogicOps`.
/// The opcodes are NOT listed on the library as they are all internal to
/// the assembly and yul doesn't seem to support using solidity constants
/// as switch case values.
uint256 constant LOGIC_OPS_LENGTH = 7;

/// @title LogicOps
/// @notice RainVM opcode pack to perform some basic logic operations.
library LogicOps {
    function applyOp(
        State memory state_,
        uint256 opcode_,
        uint256 operand_
    ) internal pure {
        require(opcode_ < LOGIC_OPS_LENGTH, "MAX_OPCODE");
        assembly {
            let stackIndex_ := mload(state_)
            // This is the start of the stack, adjusted for the leading length
            // 32 bytes.
            // i.e. reading from stackLocation_ gives the first value of the
            // stack and NOT its length.
            let stackTopLocation_ := add(
                // pointer to the stack.
                mload(add(state_, 0x20)),
                add(
                    // length of the stack
                    0x20,
                    // index of the stack
                    mul(stackIndex_, 0x20)
                )
            )

            switch opcode_
            // ISZERO
            case 0 {
                // The stackIndex_ doesn't change for iszero as there is
                // one input and output. ISZERO reads one value so the stack
                // index needs to be nonzero.
                if iszero(stackIndex_) {
                    revert(0, 0)
                }
                let location_ := sub(stackTopLocation_, 0x20)
                mstore(location_, iszero(mload(location_)))
            }
            // EAGER_IF
            // Eager because BOTH x_ and y_ must be eagerly evaluated
            // before EAGER_IF will select one of them. If both x_ and y_
            // are cheap (e.g. constant values) then this may also be the
            // simplest and cheapest way to select one of them.
            case 1 {
                // EAGER_IF reads 3 values.
                if lt(stackIndex_, 3) {
                    revert(0, 0)
                }
                // decrease stack index by 2 (3 inputs, 1 output)
                mstore(state_, sub(stackIndex_, 2))
                let location_ := sub(stackTopLocation_, 0x60)
                switch mload(location_)
                // false => use second value
                case 0 {
                    mstore(location_, mload(add(location_, 0x40)))
                }
                // true => use first value
                default {
                    mstore(location_, mload(add(location_, 0x20)))
                }
            }
            // EQUAL_TO
            case 2 {
                // EQUAL_TO reads 2 values.
                if lt(stackIndex_, 2) {
                    revert(0, 0)
                }
                // decrease stack index by 1 (2 inputs, 1 output)
                mstore(state_, sub(stackIndex_, 1))
                let location_ := sub(stackTopLocation_, 0x40)
                mstore(
                    location_,
                    eq(mload(location_), mload(add(location_, 0x20)))
                )
            }
            // LESS_THAN
            case 3 {
                // LESS_THAN reads 2 values.
                if lt(stackIndex_, 2) {
                    revert(0, 0)
                }
                // decrease stack index by 1 (2 inputs, 1 output)
                mstore(state_, sub(stackIndex_, 1))
                let location_ := sub(stackTopLocation_, 0x40)
                mstore(
                    location_,
                    lt(mload(location_), mload(add(location_, 0x20)))
                )
            }
            // GREATER_THAN
            case 4 {
                // GREATER_THAN reads 2 values.
                if lt(stackIndex_, 2) {
                    revert(0, 0)
                }
                // decrease stack index by 1 (2 inputs, 1 output)
                mstore(state_, sub(stackIndex_, 1))
                let location_ := sub(stackTopLocation_, 0x40)
                mstore(
                    location_,
                    gt(mload(location_), mload(add(location_, 0x20)))
                )
            }
            // EVERY
            // EVERY is either the first item if every item is nonzero, else 0.
            // operand_ is the length of items to check.
            // EVERY of length `0` is a noop.
            case 5 {
                // EVERY reads operand_ values.
                if lt(stackIndex_, operand_) {
                    revert(0, 0)
                }
                if iszero(iszero(operand_)) {
                    // decrease stack index by 1 less than operand_
                    mstore(state_, sub(stackIndex_, sub(operand_, 1)))
                    let location_ := sub(stackTopLocation_, mul(operand_, 0x20))
                    for {
                        let cursor_ := location_
                    } lt(cursor_, stackTopLocation_) {
                        cursor_ := add(cursor_, 0x20)
                    } {
                        // If anything is zero then EVERY is a failed check.
                        if iszero(mload(cursor_)) {
                            mstore(location_, 0)
                            break
                        }
                    }
                }
            }
            // ANY
            // ANY is the first nonzero item, else 0.
            // operand_ id the length of items to check.
            // ANY of length `0` is a noop.
            case 6 {
                // ANY reads operand_ values.
                if lt(stackIndex_, operand_) {
                    revert(0, 0)
                }
                if iszero(iszero(operand_)) {
                    // decrease stack index by 1 less than the operand_
                    mstore(state_, sub(stackIndex_, sub(operand_, 1)))
                    let location_ := sub(stackTopLocation_, mul(operand_, 0x20))
                    for {
                        let cursor_ := location_
                    } lt(cursor_, stackTopLocation_) {
                        cursor_ := add(cursor_, 0x20)
                    } {
                        // If anything is NOT zero then ANY is a successful
                        // check and can short-circuit.
                        let item_ := mload(cursor_)
                        if iszero(iszero(item_)) {
                            // Write the usable value to the top of the stack.
                            mstore(location_, item_)
                            break
                        }
                    }
                }
            }
        }
    }
}