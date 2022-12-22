// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICurve {
    // for Ellipsis: 3EPS, 2pool, val3EPS pool
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external ;

    // for Ellipsis: USDD/3EPS pool
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external;

    // For Pancake Stable Swap
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external;
}