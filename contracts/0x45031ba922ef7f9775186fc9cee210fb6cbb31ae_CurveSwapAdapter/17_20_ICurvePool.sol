// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

interface ICurvePool {
    function exchange(
        int128 i,
        int128 j,
        uint256 _dy,
        uint256 _min_dy,
        address _receiver
    ) external payable returns (uint);

    function coins(uint256 i) external returns (address);
}