// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ICurvePool {
    function get_virtual_price() external view returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);
}