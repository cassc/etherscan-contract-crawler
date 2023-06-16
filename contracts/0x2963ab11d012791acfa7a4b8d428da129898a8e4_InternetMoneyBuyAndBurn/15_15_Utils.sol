// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

abstract contract Utils {
    /** clamp the amount provided to a maximum, defaulting to provided maximum if 0 provided */
    function clamp(uint256 amount, uint256 max) pure public returns(uint256) {
        return _clamp(amount, max);
    }
    function _clamp(uint256 amount, uint256 max) internal pure returns(uint256) {
        if (amount > max) {
            return max;
        }
        return amount == 0 ? max : amount;
    }
}