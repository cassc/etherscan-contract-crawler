// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @title Library for parsing parameters from salt.
library OrderSaltParser {
    uint256 private constant _TIME_START_MASK        = 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000; // prettier-ignore
    uint256 private constant _DURATION_MASK          = 0x00000000FFFFFF00000000000000000000000000000000000000000000000000; // prettier-ignore
    uint256 private constant _INITIAL_RATE_BUMP_MASK = 0x00000000000000FFFFFF00000000000000000000000000000000000000000000; // prettier-ignore
    uint256 private constant _FEE_MASK               = 0x00000000000000000000FFFFFFFF000000000000000000000000000000000000; // prettier-ignore
    uint256 private constant _SALT_MASK              = 0x0000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore

    uint256 private constant _TIME_START_SHIFT = 224; // orderTimeMask 224-255
    uint256 private constant _DURATION_SHIFT = 200; // durationMask 200-223
    uint256 private constant _INITIAL_RATE_BUMP_SHIFT = 176; // initialRateMask 176-200
    uint256 private constant _FEE_SHIFT = 144; // orderFee 144-175

    function getStartTime(uint256 salt) internal pure returns (uint256) {
        return (salt & _TIME_START_MASK) >> _TIME_START_SHIFT;
    }

    function getDuration(uint256 salt) internal pure returns (uint256) {
        return (salt & _DURATION_MASK) >> _DURATION_SHIFT;
    }

    function getInitialRateBump(uint256 salt) internal pure returns (uint256) {
        return (salt & _INITIAL_RATE_BUMP_MASK) >> _INITIAL_RATE_BUMP_SHIFT;
    }

    function getFee(uint256 salt) internal pure returns (uint256) {
        return (salt & _FEE_MASK) >> _FEE_SHIFT;
    }

    function getSalt(uint256 salt) internal pure returns (uint256) {
        return salt & _SALT_MASK;
    }
}