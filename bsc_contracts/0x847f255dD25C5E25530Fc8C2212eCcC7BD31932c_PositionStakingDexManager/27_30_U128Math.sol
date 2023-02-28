/**
 * @author Musket
 */
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

library U128Math {
    function add(uint128 a, uint128 b) internal pure returns (uint128) {
        return a + b;
    }

    function baseToQuote(
        uint128 quantity,
        uint128 pip,
        uint128 basisPoint
    ) internal pure returns (uint128) {
        return
            uint128((uint256(quantity) * uint256(pip)) / uint256(basisPoint));
    }

    function quoteToBase(
        uint128 quantity,
        uint128 pip,
        uint128 basisPoint
    ) internal pure returns (uint128) {
        return
            uint128((uint256(quantity) * uint256(basisPoint)) / uint256(pip));
    }

    function toU256(uint128 a) internal pure returns (uint256) {
        return uint256(a);
    }

    function toInt128(uint128 a) internal pure returns (int128) {
        return int128(a);
    }

    function toInt256(uint128 a) internal pure returns (int256) {
        return int256(int128(a));
    }

    function sub(uint128 a, uint128 b) internal pure returns (uint128) {
        return a - b;
    }

    function mul(uint128 a, uint256 b) internal pure returns (uint256) {
        return uint256(a) * b;
    }
}