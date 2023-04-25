// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

abstract contract ExtensionPercent {
    uint256 internal constant PRECISION = 1e6;

    function calcPercent(
        uint256 amount,
        uint256 percent
    ) internal pure returns (uint256 share) {
        return ((amount * percent) / (PRECISION * 100));
    }

    function subtractPercentage(
        uint256 amount,
        uint256 percent
    ) internal pure returns (uint256 remains, uint256 share) {
        share = calcPercent(amount, percent);
        return (amount - share, share);
    }

    function addPercentage(
        uint256 amount,
        uint256 percent
    ) internal pure returns (uint256 remains, uint256 share) {
        share = calcPercent(amount, percent);
        return (amount + share, share);
    }
}