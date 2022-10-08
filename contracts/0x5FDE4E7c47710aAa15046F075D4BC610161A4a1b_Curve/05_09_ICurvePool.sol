// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICurvePool {
    function exchange_underlying(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external;
}

interface ICurvePoolToETH {
    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy,
        bool use_eth
    ) external;
}