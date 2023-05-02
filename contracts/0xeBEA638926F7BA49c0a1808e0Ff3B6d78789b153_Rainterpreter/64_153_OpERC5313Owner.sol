// SPDX-License-Identifier: CAL
pragma solidity =0.8.18;

import "../../../ierc5313/IERC5313.sol";
import "../../deploy/LibIntegrityCheck.sol";
import "../../run/LibInterpreterState.sol";

/// @title OpERC5313Owner
/// @notice Opcode for ERC5313 `owner`.
library OpERC5313Owner {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(uint256 contract_) internal view returns (uint256) {
        return
            uint256(
                uint160(address(EIP5313(address(uint160(contract_))).owner()))
            );
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.applyFn(stackTop_, f);
    }

    function run(
        InterpreterState memory,
        Operand,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFn(f);
    }
}