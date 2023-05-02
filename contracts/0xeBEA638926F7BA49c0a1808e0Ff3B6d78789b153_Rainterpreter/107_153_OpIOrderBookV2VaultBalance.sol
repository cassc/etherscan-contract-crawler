// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "rain.interface.orderbook/IOrderBookV2.sol";
import "../../../run/LibStackPointer.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityCheck.sol";

/// @title OpIOrderBookV2VaultBalance
/// @notice Opcode for IOrderBookV2 `vaultBalance`.
library OpIOrderBookV2VaultBalance {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(
        uint256 orderbook_,
        uint256 owner_,
        uint256 token_,
        uint256 id_
    ) internal view returns (uint256) {
        return
            uint256(
                uint160(
                    IOrderBookV2(address(uint160(orderbook_))).vaultBalance(
                        address(uint160(owner_)),
                        address(uint160(token_)),
                        id_
                    )
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

    function run(
        InterpreterState memory,
        Operand,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFn(f);
    }
}