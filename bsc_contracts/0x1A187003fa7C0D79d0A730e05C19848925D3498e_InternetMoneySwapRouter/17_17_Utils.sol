// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

abstract contract Utils {
    /** clamp the amount provided to a maximum, defaulting to provided maximum if 0 provided */
    function clamp(uint256 amount, uint256 max) pure public returns(uint256) {
        uint256 min = amount < max ? amount : max;
        return min == 0 ? max : min;
    }
}