// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import {IERC721Upgradeable as IERC721} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "../../run/LibStackPointer.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";

/// @title OpERC721BalanceOf
/// @notice Opcode for getting the current erc721 balance of an account.
library OpERC721BalanceOf {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(
        uint256 token_,
        uint256 account_
    ) internal view returns (uint256) {
        return
            IERC721(address(uint160(token_))).balanceOf(
                address(uint160(account_))
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