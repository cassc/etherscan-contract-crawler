// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/// @title OpERC1155BalanceOfBatch
/// @notice Opcode for getting the current erc1155 balance of an accounts batch.
library OpERC1155BalanceOfBatch {
    function stackPops(uint256 operand_) internal pure returns (uint256) {
        unchecked {
            require(operand_ > 0, "0_OPERAND");
            return (operand_ * 2) + 1;
        }
    }

    // Stack the return of `balanceOfBatch`.
    // Operand will be the length
    function balanceOfBatch(uint256 operand_, uint256 stackTopLocation_)
        internal
        view
        returns (uint256)
    {
        uint256 location_;
        address[] memory addresses_ = new address[](operand_);
        uint256[] memory ids_ = new uint256[](operand_);
        uint256 token_;
        assembly {
            location_ := sub(stackTopLocation_, add(0x20, mul(operand_, 0x40)))
            token_ := mload(location_)
            let cursor_ := add(location_, 0x20)

            for {
                let maxCursor_ := add(cursor_, mul(operand_, 0x20))
                let addressesCursor_ := add(addresses_, 0x20)
            } lt(cursor_, maxCursor_) {
                cursor_ := add(cursor_, 0x20)
                addressesCursor_ := add(addressesCursor_, 0x20)
            } {
                mstore(addressesCursor_, mload(cursor_))
            }

            for {
                let maxCursor_ := add(cursor_, mul(operand_, 0x20))
                let idsCursor_ := add(ids_, 0x20)
            } lt(cursor_, maxCursor_) {
                cursor_ := add(cursor_, 0x20)
                idsCursor_ := add(idsCursor_, 0x20)
            } {
                mstore(idsCursor_, mload(cursor_))
            }
        }
        uint256[] memory balances_ = IERC1155(address(uint160(token_)))
            .balanceOfBatch(addresses_, ids_);

        assembly {
            let cursor_ := location_
            for {
                let balancesCursor_ := add(balances_, 0x20)
                let balancesCursorMax_ := add(
                    balancesCursor_,
                    mul(operand_, 0x20)
                )
            } lt(balancesCursor_, balancesCursorMax_) {
                cursor_ := add(cursor_, 0x20)
                balancesCursor_ := add(balancesCursor_, 0x20)
            } {
                mstore(cursor_, mload(balancesCursor_))
            }
            stackTopLocation_ := cursor_
        }
        return stackTopLocation_;
    }
}