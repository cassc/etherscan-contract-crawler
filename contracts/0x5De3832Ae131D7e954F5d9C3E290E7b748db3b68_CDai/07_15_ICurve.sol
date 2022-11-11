// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICurvePool {
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);
}

// Curve Pool Struct
struct CurvePool {
    address pool;
    address from;
    uint256 i;
    address to;
    uint256 j;
    bool ethPool;
}

interface ICurveRouter {
    function pools(bytes32 index) external view returns (CurvePool memory);
}