// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

library SafeCast {
    function safeCastTo216(uint256 x) internal pure returns (uint216 y) {
        require(x < 1 << 216);

        y = uint216(x);
    }

    function safeCastToInt(uint256 x) internal pure returns (int256 y) {
        require(x < 1 << 255);

        y = int256(x);
    }

    function safeCastToUint(int256 x) internal pure returns (uint256 y) {
        require(x >= 0);

        y = uint256(x);
    }
}