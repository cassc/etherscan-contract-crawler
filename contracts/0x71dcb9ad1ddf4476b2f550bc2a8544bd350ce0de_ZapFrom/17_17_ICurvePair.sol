// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ICurvePair {
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;

    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy,
        bool use_eth
    ) external payable;

    function coins(uint256 i) external view returns (address);
}