// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

library Math {
    function divide(
        uint256 a,
        uint256 b,
        bool roundingUp
    ) internal pure returns (uint256 ret) {
        // In the OrderBook contract code, b is never zero.
        assembly {
            ret := add(div(a, b), and(gt(mod(a, b), 0), roundingUp))
        }
    }
}