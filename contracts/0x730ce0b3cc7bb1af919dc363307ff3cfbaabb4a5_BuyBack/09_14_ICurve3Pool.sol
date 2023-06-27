// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

/// Curve 3pool interface
interface ICurve3Pool {
    function get_virtual_price() external view returns (uint256);

    function calc_withdraw_one_coin(
        uint256 _token_amount,
        int128 i
    ) external view returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function balanceOf(address account) external view returns (uint256);
}