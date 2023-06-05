// SPDX-License-Identifier: ISC

pragma solidity ^0.8.13;

interface ICurveRegistry {
    function find_pool_for_coins(
        address _from,
        address _to,
        uint256 _index
    ) external returns (address);

    function get_coin_indices(
        address _pool,
        address _from,
        address _to
    )
    external
    returns (
        int128,
        int128,
        bool
    );
}