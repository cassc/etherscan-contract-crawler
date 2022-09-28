// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import {State} from "../../RainVM.sol";

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @dev Opcode for `IERC721` `balanceOf`.
uint256 constant OPCODE_BALANCE_OF = 0;
/// @dev Opcode for `IERC721` `ownerOf`.
uint256 constant OPCODE_OWNER_OF = 1;
/// @dev Number of provided opcodes for `IERC721Ops`.
uint256 constant IERC721_OPS_LENGTH = 2;

/// @title IERC721Ops
/// @notice RainVM opcode pack to read the IERC721 interface.
library IERC721Ops {
    function applyOp(
        State memory state_,
        uint256 opcode_,
        uint256
    ) internal view {
        unchecked {
            require(opcode_ < IERC721_OPS_LENGTH, "MAX_OPCODE");

            state_.stackIndex--;
            uint256 baseIndex_ = state_.stackIndex - 1;
            // Stack the return of `balanceOf`.
            if (opcode_ == OPCODE_BALANCE_OF) {
                state_.stack[baseIndex_] = IERC721(
                    address(uint160(state_.stack[baseIndex_]))
                ).balanceOf(address(uint160(state_.stack[state_.stackIndex])));
            }
            // Stack the return of `ownerOf`.
            else if (opcode_ == OPCODE_OWNER_OF) {
                state_.stack[baseIndex_] = uint256(
                    uint160(
                        IERC721(address(uint160(state_.stack[baseIndex_])))
                            .ownerOf(state_.stack[state_.stackIndex])
                    )
                );
            }
        }
    }
}