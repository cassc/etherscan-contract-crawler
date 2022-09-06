// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

import {BytesLib} from "../intergrations/uniswap/BytesLib.sol";

library Path {
    using BytesLib for bytes;

    uint256 constant ADDR_SIZE = 20;
    uint256 constant FEE_SIZE = 3;

    function decode(bytes memory path) internal pure returns (address token0, address token1) {
        if (path.length >= 2 * ADDR_SIZE + FEE_SIZE) {
            token0 = path.toAddress(0);
            token1 = path.toAddress(path.length - ADDR_SIZE);
        }
        require(token0 != address(0) && token1 != address(0));
    }
}