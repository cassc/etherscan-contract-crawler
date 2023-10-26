//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

library Sqrt {
    /**
     * @dev This code is written by Noah Zinsmeister @ Uniswap
     * https://github.com/Uniswap/uniswap-v2-core/blob/v1.0.1/contracts/libraries/Math.sol
     */
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}