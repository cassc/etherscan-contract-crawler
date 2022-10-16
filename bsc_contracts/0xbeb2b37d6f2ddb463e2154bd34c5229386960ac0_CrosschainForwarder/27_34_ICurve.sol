// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

interface ICurve {
    function exchange_underlying(
        int128 _i,
        int128 _j,
        uint256 _dx,
        uint256 _min_dy
    ) external returns (uint256);

    // @external
    // def exchange_underlying(
    //     _pool: address,
    //     _i: int128,
    //     _j: int128,
    //     _dx: uint256,
    //     _min_dy: uint256,
    //     _receiver: address = msg.sender,
    //     _use_underlying: bool = True
    // ) -> uint256:
    function exchange_underlying(
        address _pool,
        int128 _i,
        int128 _j,
        uint256 _dx,
        uint256 _min_dy,
        address _receiver
    ) external returns (uint256);
}