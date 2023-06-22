// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import {State} from "../../RainVM.sol";

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/// @dev Opcode for `IERC1155` `balanceOf`.
uint256 constant OPCODE_BALANCE_OF = 0;
/// @dev Opcode for `IERC1155` `balanceOfBatch`.
uint256 constant OPCODE_BALANCE_OF_BATCH = 1;
/// @dev Number of provided opcodes for `IERC1155Ops`.
uint256 constant IERC1155_OPS_LENGTH = 2;

/// @title IERC1155Ops
/// @notice RainVM opcode pack to read the IERC1155 interface.
library IERC1155Ops {
    function applyOp(
        State memory state_,
        uint256 opcode_,
        uint256 operand_
    ) internal view {
        unchecked {
            require(opcode_ < IERC1155_OPS_LENGTH, "MAX_OPCODE");

            // Stack the return of `balanceOf`.
            if (opcode_ == OPCODE_BALANCE_OF) {
                state_.stackIndex -= 2;
                uint256 baseIndex_ = state_.stackIndex - 1;
                state_.stack[baseIndex_] = IERC1155(
                    address(uint160(state_.stack[baseIndex_]))
                ).balanceOf(
                        address(uint160(state_.stack[baseIndex_ + 1])),
                        state_.stack[baseIndex_ + 2]
                    );
            }
            // Stack the return of `balanceOfBatch`.
            // Operand will be the length
            else if (opcode_ == OPCODE_BALANCE_OF_BATCH) {
                uint256 len_ = operand_ + 1;
                address[] memory addresses_ = new address[](len_);
                uint256[] memory ids_ = new uint256[](len_);

                // Consumes (2 * len_ + 1) inputs and produces len_ outputs.
                state_.stackIndex = state_.stackIndex - (len_ + 1);
                uint256 baseIndex_ = state_.stackIndex - len_;

                IERC1155 token_ = IERC1155(
                    address(uint160(state_.stack[baseIndex_]))
                );
                for (uint256 i_ = 0; i_ < len_; i_++) {
                    addresses_[i_] = address(
                        uint160(state_.stack[baseIndex_ + i_ + 1])
                    );
                    ids_[i_] = state_.stack[baseIndex_ + len_ + i_ + 1];
                }

                uint256[] memory balances_ = token_.balanceOfBatch(
                    addresses_,
                    ids_
                );

                for (uint256 i_ = 0; i_ < len_; i_++) {
                    state_.stack[baseIndex_ + i_] = balances_[i_];
                }
            }
        }
    }
}