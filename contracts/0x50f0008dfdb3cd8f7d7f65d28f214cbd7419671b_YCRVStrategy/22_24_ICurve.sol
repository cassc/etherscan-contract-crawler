// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface ICurve {
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function get_dx_underlying(
        int128 i,
        int128 j,
        uint256 dy
    ) external view returns (uint256);

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function get_dx(
        int128 i,
        int128 j,
        uint256 dy
    ) external view returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function last_price() external view returns (uint256);

    function price_oracle() external view returns (uint256);

    function price_oracle(uint256 k) external view returns (uint256);

    function calc_withdraw_one_coin(
        uint256 token_amount,
        uint256 i
    ) external view returns (uint256);

    function add_liquidity(
        uint256[2] memory amounts,
        uint256 min_mint_amount,
        bool use_eth
    ) external payable returns (uint256);

    function add_liquidity(
        uint256[2] memory amounts,
        uint256 min_mint_amount,
        address receiver
    ) external payable returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        uint256 i,
        uint256 min_amount,
        bool use_eth
    ) external returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount,
        address receiver
    ) external returns (uint256);

    function lp_price() external view returns (uint256);
}

interface ICurveSwapRouter {
    function exchange_multiple(
        address[9] memory _route,
        uint256[3][4] memory _swap_params,
        uint256 _amount,
        uint256 _expected
    ) external payable returns (uint256);

    function exchange_multiple(
        address[9] memory _route,
        uint256[3][4] memory _swap_params,
        uint256 _amount,
        uint256 _expected,
        address[4] memory _pools
    ) external payable returns (uint256);
}

interface ICurve2 {
    function calc_withdraw_one_coin(
        uint256 token_amount,
        int128 i
    ) external view returns (uint256);
}