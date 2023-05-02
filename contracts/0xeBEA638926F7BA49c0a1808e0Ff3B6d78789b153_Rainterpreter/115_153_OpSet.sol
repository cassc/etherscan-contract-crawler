// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../../run/LibStackPointer.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";
import "../../../kv/LibMemoryKV.sol";

/// @title OpSet
/// @notice Opcode for recording k/v state changes to be set in storage.
library OpSet {
    using LibStackPointer for StackPointer;
    using LibInterpreterState for InterpreterState;
    using LibIntegrityCheck for IntegrityCheckState;
    using LibMemoryKV for MemoryKV;

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        unchecked {
            function(uint256, uint256) internal pure fn_;
            return integrityCheckState_.applyFn(stackTop_, fn_);
        }
    }

    function run(
        InterpreterState memory state_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        unchecked {
            uint256 k_;
            uint256 v_;
            (stackTop_, v_) = stackTop_.pop();
            (stackTop_, k_) = stackTop_.pop();
            state_.stateKV = state_.stateKV.setVal(
                MemoryKVKey.wrap(k_),
                MemoryKVVal.wrap(v_)
            );
            return stackTop_;
        }
    }
}