// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ICurveFi {
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
}