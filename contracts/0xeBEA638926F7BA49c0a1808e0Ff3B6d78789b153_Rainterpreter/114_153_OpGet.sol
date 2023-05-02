// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../../run/LibStackPointer.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";
import "../../../kv/LibMemoryKV.sol";

/// @title OpGet
/// @notice Opcode for reading from storage.
library OpGet {
    using LibStackPointer for StackPointer;
    using LibInterpreterState for InterpreterState;
    using LibIntegrityCheck for IntegrityCheckState;
    using LibMemoryKV for MemoryKV;
    using LibMemoryKV for MemoryKVPtr;

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        unchecked {
            // Pop key
            // Stack value
            function(uint256) internal pure returns (uint256) fn_;
            return integrityCheckState_.applyFn(stackTop_, fn_);
        }
    }

    /// Implements runtime behaviour of the `get` opcode. Attempts to lookup the
    /// key in the memory key/value store then falls back to the interpreter's
    /// storage interface as an external call. If the key is not found in either,
    /// the value will fallback to `0` as per default Solidity/EVM behaviour.
    /// @param interpreterState_ The interpreter state of the current eval.
    /// @param stackTop_ Pointer to the current stack top.
    function run(
        InterpreterState memory interpreterState_,
        Operand,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        uint256 k_;
        (stackTop_, k_) = stackTop_.pop();
        MemoryKVPtr kvPtr_ = interpreterState_.stateKV.getPtr(
            MemoryKVKey.wrap(k_)
        );
        uint256 v_ = 0;
        // Cache MISS, get from external store.
        if (MemoryKVPtr.unwrap(kvPtr_) == 0) {
            v_ = interpreterState_.store.get(interpreterState_.namespace, k_);
            // Push fetched value to memory to make subsequent lookups on the
            // same key find a cache HIT.
            interpreterState_.stateKV = interpreterState_.stateKV.setVal(
                MemoryKVKey.wrap(k_),
                MemoryKVVal.wrap(v_)
            );
        }
        // Cache HIT.
        else {
            v_ = MemoryKVVal.unwrap(kvPtr_.readPtrVal());
        }
        return stackTop_.push(v_);
    }
}