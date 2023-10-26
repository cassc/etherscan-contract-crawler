// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFactory {
    function exchange(
        uint128 i,
        uint128 j,
        uint256 _dx,
        uint256 _min_dy,
        address _receiver
    ) external returns (uint256);
}