// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICurveCVXETH {
    function token() external view returns (address);

    function coins(uint256 i) external view returns (address);

    function A() external view returns (uint256);

    function gamma() external view returns (uint256);

    function fee() external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy,
        bool use_eth
    ) external returns (uint256);

    function exchange_underlying(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

    function get_dy(
        uint256 i,
        uint256 j,
        uint256 dx
    ) external view returns (uint256);

    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount)
        external
        returns (uint256);

    function add_liquidity(
        uint256[2] memory amounts,
        uint256 min_mint_amount,
        bool use_eth
    ) external returns (uint256);

    function remove_liquidity(uint256 _amount, uint256[2] memory min_amounts)
        external;

    function remove_liquidity(
        uint256 _amount,
        uint256[2] memory min_amounts,
        bool use_eth
    ) external;

    function calc_token_amount(uint256[2] memory amounts)
        external
        view
        returns (uint256);

    function calc_withdraw_one_coin(uint256 token_amount, uint256 i)
        external
        view
        returns (uint256);

    function remove_liquidity_one_coin(
        uint256 token_amount,
        uint256 i,
        uint256 min_amount
    ) external returns (uint256);

    function remove_liquidity_one_coin(
        uint256 token_amount,
        uint256 i,
        uint256 min_amount,
        bool use_eth
    ) external returns (uint256);

    function claim_admin_fees() external;

    function ramp_A_gamma(
        uint256 future_A,
        uint256 future_gamma,
        uint256 future_time
    ) external;

    function stop_ramp_A_gamma() external;

    function commit_new_parameters(
        uint256 _new_mid_fee,
        uint256 _new_out_fee,
        uint256 _new_admin_fee,
        uint256 _new_fee_gamma,
        uint256 _new_allowed_extra_profit,
        uint256 _new_adjustment_step,
        uint256 _new_ma_half_time
    ) external;

    function apply_new_parameters() external;

    function revert_new_parameters() external;

    function commit_transfer_ownership(address _owner) external;

    function apply_transfer_ownership() external;

    function revert_transfer_ownership() external;

    function kill_me() external;

    function unkill_me() external;

    function set_admin_fee_receiver(address _admin_fee_receiver) external;

    function lp_price() external view returns (uint256);

    function price_scale() external view returns (uint256);

    function price_oracle() external view returns (uint256);

    function last_prices() external view returns (uint256);

    function last_prices_timestamp() external view returns (uint256);

    function initial_A_gamma() external view returns (uint256);

    function future_A_gamma() external view returns (uint256);

    function initial_A_gamma_time() external view returns (uint256);

    function future_A_gamma_time() external view returns (uint256);

    function allowed_extra_profit() external view returns (uint256);

    function future_allowed_extra_profit() external view returns (uint256);

    function fee_gamma() external view returns (uint256);

    function future_fee_gamma() external view returns (uint256);

    function adjustment_step() external view returns (uint256);

    function future_adjustment_step() external view returns (uint256);

    function ma_half_time() external view returns (uint256);

    function future_ma_half_time() external view returns (uint256);

    function mid_fee() external view returns (uint256);

    function out_fee() external view returns (uint256);

    function admin_fee() external view returns (uint256);

    function future_mid_fee() external view returns (uint256);

    function future_out_fee() external view returns (uint256);

    function future_admin_fee() external view returns (uint256);

    function balances(uint256 arg0) external view returns (uint256);

    function D() external view returns (uint256);

    function owner() external view returns (address);

    function future_owner() external view returns (address);

    function xcp_profit() external view returns (uint256);

    function xcp_profit_a() external view returns (uint256);

    function virtual_price() external view returns (uint256);

    function is_killed() external view returns (bool);

    function kill_deadline() external view returns (uint256);

    function transfer_ownership_deadline() external view returns (uint256);

    function admin_actions_deadline() external view returns (uint256);

    function admin_fee_receiver() external view returns (address);
}