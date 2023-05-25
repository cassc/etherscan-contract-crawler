// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

library IntSafeMath {
    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}