// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface ISaddleDex {
    function getTokenIndex(address tokenAddress) external view returns (uint8);

    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external returns (uint256);
}