// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import "./IMetaPoolBase.sol";

uint256 constant N_COINS = 3;

//solhint-disable
interface IMetaPool3 is IMetaPoolBase {
    function coins() external view returns (uint256[N_COINS] memory);

    function balances(uint256) external view returns (uint256);

    function get_balances() external view returns (uint256[N_COINS] memory);

    function get_previous_balances() external view returns (uint256[N_COINS] memory);

    function get_price_cumulative_last() external view returns (uint256[N_COINS] memory);

    function get_twap_balances(
        uint256[N_COINS] memory _first_balances,
        uint256[N_COINS] memory _last_balances,
        uint256 _time_elapsed
    ) external view returns (uint256[N_COINS] memory);

    function calc_token_amount(uint256[N_COINS] memory _amounts, bool _is_deposit) external view returns (uint256);

    function calc_token_amount(
        uint256[N_COINS] memory _amounts,
        bool _is_deposit,
        bool _previous
    ) external view returns (uint256);

    function add_liquidity(uint256[N_COINS] memory _amounts, uint256 _min_mint_amount) external;

    function add_liquidity(
        uint256[N_COINS] memory _amounts,
        uint256 _min_mint_amount,
        address _receiver
    ) external returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx,
        uint256[N_COINS] memory _balances
    ) external view returns (uint256);

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256[N_COINS] memory _balances
    ) external view returns (uint256);

    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function remove_liquidity_one_coin(
        uint256 _burn_amount,
        int128 i,
        uint256 _min_received
    ) external;

    function remove_liquidity(uint256 _burn_amount, uint256[N_COINS] memory _min_amounts) external;

    function remove_liquidity(
        uint256 _burn_amount,
        uint256[N_COINS] memory _min_amounts,
        address _receiver
    ) external;

    function remove_liquidity_imbalance(uint256[N_COINS] memory _amounts, uint256 _max_burn_amount) external;

    function remove_liquidity_imbalance(
        uint256[N_COINS] memory _amounts,
        uint256 _max_burn_amount,
        address _receiver
    ) external;

    // overload functions because some pools requires i to be an int128 or an uint256
    function calc_withdraw_one_coin(uint256 _burn_amount, uint256 i) external view returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _burn_amount,
        uint256 i,
        uint256 _min_received
    ) external;
}