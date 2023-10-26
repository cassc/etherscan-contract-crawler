// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

library OvnMath {
    uint256 constant BASIS_DENOMINATOR = 1e6;

    function abs(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x > y) ? (x - y) : (y - x);
    }

    function addBasisPoints(
        uint256 amount,
        uint256 basisPoints
    ) internal pure returns (uint256) {
        return (amount * (BASIS_DENOMINATOR + basisPoints)) / BASIS_DENOMINATOR;
    }

    function reverseAddBasisPoints(
        uint256 amount,
        uint256 basisPoints
    ) internal pure returns (uint256) {
        return (amount * BASIS_DENOMINATOR) / (BASIS_DENOMINATOR + basisPoints);
    }

    function subBasisPoints(
        uint256 amount,
        uint256 basisPoints
    ) internal pure returns (uint256) {
        return (amount * (BASIS_DENOMINATOR - basisPoints)) / BASIS_DENOMINATOR;
    }

    function reverseSubBasisPoints(
        uint256 amount,
        uint256 basisPoints
    ) internal pure returns (uint256) {
        return (amount * BASIS_DENOMINATOR) / (BASIS_DENOMINATOR - basisPoints);
    }
}