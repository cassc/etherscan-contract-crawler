// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

uint256 constant N_COINS = 2;

interface ICurvePoolStETH {
    function coins(uint256) external view returns (address);

    function balances(uint256) external view returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external payable;

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function add_liquidity(
        uint256[N_COINS] memory amounts,
        uint256 min_mint_amount
    ) external payable;

    function remove_liquidity(
        uint256 _amount,
        uint256[N_COINS] memory min_amounts
    ) external;

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function lp_token() external view returns (address);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function remove_liquidity_imbalance(
        uint256[N_COINS] memory amounts,
        uint256 max_burn_amount
    ) external;

    function calc_token_amount(
        uint256[N_COINS] calldata _amounts,
        bool _is_deposit
    ) external view returns (uint256);

    function A() external view returns (uint256);

    function A_precise() external view returns (uint256);

    function calc_withdraw_one_coin(uint256 _burn_amount, int128 i)
        external
        view
        returns (uint256);

    function admin_balances(uint256 i) external view returns (uint256);

    function admin() external view returns (address);

    function fee() external view returns (uint256);

    function admin_fee() external view returns (uint256);

    function block_timestamp_last() external view returns (uint256);

    function initial_A() external view returns (uint256);

    function future_A() external view returns (uint256);

    function initial_A_time() external view returns (uint256);

    function future_A_time() external view returns (uint256);
}