// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title OpERC20BalanceOf
/// @notice Opcode for ERC20 `balanceOf`.
library OpERC20BalanceOf {
    /// Stack `balanceOf`.
    function balanceOf(uint256, uint256 stackTopLocation_)
        internal
        view
        returns (uint256)
    {
        uint256 location_;
        uint256 token_;
        uint256 account_;
        assembly {
            stackTopLocation_ := sub(stackTopLocation_, 0x20)
            location_ := sub(stackTopLocation_, 0x20)
            token_ := mload(location_)
            account_ := mload(stackTopLocation_)
        }
        uint256 balance_ = IERC20(address(uint160(token_))).balanceOf(
            address(uint160(account_))
        );
        assembly {
            mstore(location_, balance_)
        }
        return stackTopLocation_;
    }
}