// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IVyperUnderlyingSwap {
    function exchange(
        int128 tokenIndexFrom,
        int128 tokenIndexTo,
        uint256 dx,
        uint256 minDy
    ) external;

    function exchange_underlying(
        int128 tokenIndexFrom,
        int128 tokenIndexTo,
        uint256 dx,
        uint256 minDy
    ) external;
}