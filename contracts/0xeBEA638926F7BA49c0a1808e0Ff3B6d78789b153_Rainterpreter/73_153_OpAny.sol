// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;
import "../../../run/LibStackPointer.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityCheck.sol";

/// @title OpAny
/// @notice Opcode to compare the top N stack values.
library OpAny {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand operand_,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        function(uint256[] memory) internal view returns (uint256) fn_;
        return
            integrityCheckState_.applyFn(
                stackTop_,
                fn_,
                Operand.unwrap(operand_)
            );
    }

    // ANY
    // ANY is the first nonzero item, else 0.
    // operand_ id the length of items to check.
    function run(
        InterpreterState memory,
        Operand operand_,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        StackPointer bottom_ = stackTop_.down(Operand.unwrap(operand_));
        for (
            StackPointer i_ = bottom_;
            StackPointer.unwrap(i_) < StackPointer.unwrap(stackTop_);
            i_ = i_.up()
        ) {
            uint256 item_ = i_.peekUp();
            if (item_ > 0) {
                return bottom_.push(item_);
            }
        }
        return bottom_.up();
    }
}