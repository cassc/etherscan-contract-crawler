// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;
import "../../../run/LibStackPointer.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityCheck.sol";

/// @title OpEagerIf
/// @notice Opcode for selecting a value based on a condition.
library OpEagerIf {
    using LibIntegrityCheck for IntegrityCheckState;
    using LibStackPointer for StackPointer;

    function f(
        uint256 a_,
        uint256[] memory bs_,
        uint256[] memory cs_
    ) internal pure returns (uint256[] memory) {
        return a_ > 0 ? bs_ : cs_;
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
                Operand.unwrap(operand_) + 1
            );
    }

    /// Eager because BOTH x_ and y_ must be eagerly evaluated
    /// before EAGER_IF will select one of them. If both x_ and y_
    /// are cheap (e.g. constant values) then this may also be the
    /// simplest and cheapest way to select one of them.
    function run(
        InterpreterState memory,
        Operand operand_,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        unchecked {
            return stackTop_.applyFn(f, Operand.unwrap(operand_) + 1);
        }
    }
}