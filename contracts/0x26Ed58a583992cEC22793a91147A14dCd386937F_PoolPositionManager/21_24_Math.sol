// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

library Math {
    uint256 constant MAX_BIT = 0x8000000000000000000000000000000000000000000000000000000000000000;
    uint256 constant DEFAULT_SCALE = 1;

    function clip(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? 0 : x - y;
    }

    function toScale(uint256 amount, uint256 scaleFactor, bool ceil) internal pure returns (uint256) {
        if (scaleFactor == DEFAULT_SCALE || amount == 0) {
            return amount;
        } else if ((scaleFactor & MAX_BIT) != 0) {
            return amount * (scaleFactor & ~MAX_BIT);
        } else {
            return (ceil && mulmod(amount, 1, scaleFactor) != 0) ? amount / scaleFactor + 1 : amount / scaleFactor;
        }
    }

    function fromScale(uint256 amount, uint256 scaleFactor) internal pure returns (uint256) {
        if (scaleFactor == DEFAULT_SCALE) {
            return amount;
        } else if ((scaleFactor & MAX_BIT) != 0) {
            return amount / (scaleFactor & ~MAX_BIT);
        } else {
            return amount * scaleFactor;
        }
    }
}