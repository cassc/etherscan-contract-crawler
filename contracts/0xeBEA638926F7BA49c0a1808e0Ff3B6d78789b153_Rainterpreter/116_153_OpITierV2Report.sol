// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../../tier/ITierV2.sol";
import "../../run/LibStackPointer.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";

/// @title OpITierV2Report
/// @notice Exposes `ITierV2.report` as an opcode.
library OpITierV2Report {
    using LibStackPointer for StackPointer;
    using LibStackPointer for uint256[];
    using LibIntegrityCheck for IntegrityCheckState;

    function f(
        uint256 tierContract_,
        uint256 account_,
        uint256[] memory context_
    ) internal view returns (uint256) {
        return
            ITierV2(address(uint160(tierContract_))).report(
                address(uint160(account_)),
                context_
            );
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

    // Stack the `report` returned by an `ITierV2` contract.
    function run(
        InterpreterState memory,
        Operand operand_,
        StackPointer stackTop_
    ) internal view returns (StackPointer stackTopAfter_) {
        return stackTop_.applyFn(f, Operand.unwrap(operand_));
    }
}