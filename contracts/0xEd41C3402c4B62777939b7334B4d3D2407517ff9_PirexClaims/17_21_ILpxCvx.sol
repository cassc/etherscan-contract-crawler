// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ILpxCvx {
    enum Token {
        CVX,
        pxCVX
    }

    function swap(
        Token source,
        uint256 amount,
        uint256 minReceived,
        uint256 fromIndex,
        uint256 toIndex
    ) external;

    function wrap(uint256 amount) external;
}