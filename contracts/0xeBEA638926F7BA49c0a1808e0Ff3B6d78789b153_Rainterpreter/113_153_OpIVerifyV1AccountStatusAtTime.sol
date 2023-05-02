// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../../../verify/IVerifyV1.sol";
import "../../../run/LibStackPointer.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityCheck.sol";

/// @title OpIVerifyV1AccountStatusAtTime
/// @notice Opcode for IVerifyV1 `accountStatusAtTime`.
library OpIVerifyV1AccountStatusAtTime {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(
        uint256 contract_,
        uint256 account_,
        uint256 timestamp_
    ) internal view returns (uint256) {
        return
            VerifyStatus.unwrap(
                IVerifyV1(address(uint160(contract_))).accountStatusAtTime(
                    address(uint160(account_)),
                    timestamp_
                )
            );
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.applyFn(stackTop_, f);
    }

    /// Stack `token`.
    function run(
        InterpreterState memory,
        Operand,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFn(f);
    }
}