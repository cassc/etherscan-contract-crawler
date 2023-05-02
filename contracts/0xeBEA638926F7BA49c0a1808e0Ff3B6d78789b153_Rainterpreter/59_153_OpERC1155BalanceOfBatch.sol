// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import {IERC1155Upgradeable as IERC1155} from "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "../../run/LibStackPointer.sol";
import "sol.lib.memory/LibUint256Array.sol";
import "rain.lib.typecast/LibCast.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";

/// @title OpERC1155BalanceOfBatch
/// @notice Opcode for getting the current erc1155 balance of an accounts batch.
library OpERC1155BalanceOfBatch {
    using LibStackPointer for StackPointer;
    using LibCast for uint256[];
    using LibIntegrityCheck for IntegrityCheckState;

    function f(
        uint256 token_,
        uint256[] memory accounts_,
        uint256[] memory ids_
    ) internal view returns (uint256[] memory) {
        return
            IERC1155(address(uint160(token_))).balanceOfBatch(
                accounts_.asAddressesArray(),
                ids_
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

    // Operand will be the length
    function run(
        InterpreterState memory,
        Operand operand_,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFn(f, Operand.unwrap(operand_));
    }
}