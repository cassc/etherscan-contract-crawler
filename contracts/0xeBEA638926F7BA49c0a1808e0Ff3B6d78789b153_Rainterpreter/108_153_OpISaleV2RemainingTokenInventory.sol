// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "rain.interface.sale/ISaleV2.sol";
import "../../../run/LibStackPointer.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityCheck.sol";

/// @title OpISaleV2RemainingTokenInventory
/// @notice Opcode for ISaleV2 `remainingTokenInventory`.
library OpISaleV2RemainingTokenInventory {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(uint256 sale_) internal view returns (uint256) {
        return ISaleV2(address(uint160(sale_))).remainingTokenInventory();
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.applyFn(stackTop_, f);
    }

    /// Stack `remainingTokenInventory`.
    function run(
        InterpreterState memory,
        Operand,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFn(f);
    }
}