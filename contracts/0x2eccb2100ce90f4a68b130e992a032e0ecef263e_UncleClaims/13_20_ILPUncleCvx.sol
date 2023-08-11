// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface ILPUncleCvx {
    enum Token {
        CVX,
        uncleCVX
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