// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import {State} from "../../RainVM.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @dev Opcode for `IERC20` `balanceOf`.
uint256 constant OPCODE_BALANCE_OF = 0;
/// @dev Opcode for `IERC20` `totalSupply`.
uint256 constant OPCODE_TOTAL_SUPPLY = 1;
/// @dev Number of provided opcodes for `IERC20Ops`.
uint256 constant IERC20_OPS_LENGTH = 2;

/// @title IERC20Ops
/// @notice RainVM opcode pack to read the IERC20 interface.
library IERC20Ops {
    function applyOp(
        State memory state_,
        uint256 opcode_,
        uint256
    ) internal view {
        unchecked {
            require(opcode_ < IERC20_OPS_LENGTH, "MAX_OPCODE");

            // Stack the return of `balanceOf`.
            if (opcode_ == OPCODE_BALANCE_OF) {
                state_.stackIndex--;
                uint256 baseIndex_ = state_.stackIndex - 1;
                state_.stack[baseIndex_] = IERC20(
                    address(uint160(state_.stack[baseIndex_]))
                ).balanceOf(address(uint160(state_.stack[state_.stackIndex])));
            }
            // Stack the return of `totalSupply`.
            else if (opcode_ == OPCODE_TOTAL_SUPPLY) {
                uint256 baseIndex_ = state_.stackIndex - 1;
                state_.stack[baseIndex_] = IERC20(
                    address(uint160(state_.stack[baseIndex_]))
                ).totalSupply();
            }
        }
    }
}