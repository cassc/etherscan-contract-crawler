// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import {State} from "../../RainVM.sol";

/// @dev Opcode for the block number.
uint256 constant OPCODE_BLOCK_NUMBER = 0;
/// @dev Opcode for the block timestamp.
uint256 constant OPCODE_BLOCK_TIMESTAMP = 1;
/// @dev Opcode for the `msg.sender`.
uint256 constant OPCODE_SENDER = 2;
/// @dev Opcode for `this` address of the current contract.
uint256 constant OPCODE_THIS_ADDRESS = 3;
/// @dev Number of provided opcodes for `BlockOps`.
uint256 constant EVM_CONSTANT_OPS_LENGTH = 4;

/// @title EVMConstantOps
/// @notice RainVM opcode pack to access constants from the EVM environment.
library EVMConstantOps {
    function applyOp(
        State memory state_,
        uint256 opcode_,
        uint256
    ) internal view {
        unchecked {
            require(opcode_ < EVM_CONSTANT_OPS_LENGTH, "MAX_OPCODE");
            // Stack the current `block.number`.
            if (opcode_ == OPCODE_BLOCK_NUMBER) {
                state_.stack[state_.stackIndex] = block.number;
            }
            // Stack the current `block.timestamp`.
            else if (opcode_ == OPCODE_BLOCK_TIMESTAMP) {
                // solhint-disable-next-line not-rely-on-time
                state_.stack[state_.stackIndex] = block.timestamp;
            } else if (opcode_ == OPCODE_SENDER) {
                // Stack the `msg.sender`.
                state_.stack[state_.stackIndex] = uint256(uint160(msg.sender));
            } else {
                state_.stack[state_.stackIndex] = uint256(
                    uint160(address(this))
                );
            }
            state_.stackIndex++;
        }
    }
}