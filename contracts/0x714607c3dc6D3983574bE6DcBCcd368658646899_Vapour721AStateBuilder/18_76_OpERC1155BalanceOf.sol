// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/// @title OpERC1155BalanceOf
/// @notice Opcode for getting the current erc1155 balance of an account.
library OpERC1155BalanceOf {
    // Stack the return of `balanceOf`.
    function balanceOf(uint256, uint256 stackTopLocation_)
        internal
        view
        returns (uint256)
    {
        uint256 location_;
        uint256 token_;
        uint256 account_;
        uint256 id_;
        assembly {
            location_ := sub(stackTopLocation_, 0x60)
            stackTopLocation_ := add(location_, 0x20)
            token_ := mload(location_)
            account_ := mload(stackTopLocation_)
            id_ := mload(add(location_, 0x40))
        }
        uint256 result_ = IERC1155(address(uint160(token_))).balanceOf(
            address(uint160(account_)),
            id_
        );
        assembly {
            mstore(location_, result_)
        }
        return stackTopLocation_;
    }
}