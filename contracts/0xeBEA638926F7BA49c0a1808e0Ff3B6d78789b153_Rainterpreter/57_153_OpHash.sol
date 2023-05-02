// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../run/LibStackPointer.sol";
import "sol.lib.memory/LibUint256Array.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";

/// @title OpHash
/// @notice Opcode for hashing a list of values.
library OpHash {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(uint256[] memory values_) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(values_)));
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand operand_,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return
            integrityCheckState_.applyFn(
                stackTop_,
                f,
                Operand.unwrap(operand_)
            );
    }

    // Stack the return of `balanceOfBatch`.
    // Operand will be the length
    function run(
        InterpreterState memory,
        Operand operand_,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFn(f, Operand.unwrap(operand_));
    }
}