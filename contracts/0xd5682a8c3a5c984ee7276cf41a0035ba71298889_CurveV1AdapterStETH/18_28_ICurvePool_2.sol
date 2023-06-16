// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {ICurvePool} from "./ICurvePool.sol";

uint256 constant N_COINS = 2;

/// @title ICurvePool2Assets
/// @dev Extends original pool contract with liquidity functions
interface ICurvePool2Assets is ICurvePool {
    function add_liquidity(uint256[N_COINS] memory amounts, uint256 min_mint_amount) external;

    function remove_liquidity(uint256 _amount, uint256[N_COINS] memory min_amounts) external;

    function remove_liquidity_imbalance(uint256[N_COINS] calldata amounts, uint256 max_burn_amount) external;

    function calc_token_amount(uint256[N_COINS] calldata _amounts, bool _is_deposit) external view returns (uint256);

    function get_twap_balances(
        uint256[N_COINS] calldata _first_balances,
        uint256[N_COINS] calldata _last_balances,
        uint256 _time_elapsed
    ) external view returns (uint256[N_COINS] memory);

    function get_balances() external view returns (uint256[N_COINS] memory);

    function get_previous_balances() external view returns (uint256[N_COINS] memory);

    function get_price_cumulative_last() external view returns (uint256[N_COINS] memory);
}