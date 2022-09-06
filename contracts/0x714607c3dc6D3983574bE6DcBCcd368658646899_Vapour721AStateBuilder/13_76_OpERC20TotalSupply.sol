// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title OpERC20TotalSupply
/// @notice Opcode for ERC20 `totalSupply`.
library OpERC20TotalSupply {
    // Stack the return of `totalSupply`.
    function totalSupply(uint256, uint256 stackTopLocation_)
        internal
        view
        returns (uint256)
    {
        uint256 location_;
        uint256 token_;
        assembly {
            location_ := sub(stackTopLocation_, 0x20)
            token_ := mload(location_)
        }
        uint256 supply_ = IERC20(address(uint160(token_))).totalSupply();
        assembly {
            mstore(location_, supply_)
        }
        return stackTopLocation_;
    }
}