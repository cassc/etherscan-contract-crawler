// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//solhint-disable
interface IMetaPool is IERC20 {
    function coins() external view returns (uint256[] memory);

    function get_balances() external view returns (uint256[] memory);

    function get_previous_balances() external view returns (uint256[] memory);

    function get_twap_balances(
        uint256[] memory _first_balances,
        uint256[] memory _last_balances,
        uint256 _time_elapsed
    ) external view returns (uint256[] memory);

    function get_price_cumulative_last() external view returns (uint256[] memory);

    function admin_fee() external view returns (uint256);

    function A() external view returns (uint256);

    function A_precise() external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function calc_token_amount(uint256[] memory _amounts, bool _is_deposit) external view returns (uint256);

    function calc_token_amount(
        uint256[] memory _amounts,
        bool _is_deposit,
        bool _previous
    ) external view returns (uint256);

    function add_liquidity(uint256[] memory _amounts, uint256 _min_mint_amount) external returns (uint256);

    function add_liquidity(
        uint256[] memory _amounts,
        uint256 _min_mint_amount,
        address _receiver
    ) external returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx,
        uint256[] memory _balances
    ) external view returns (uint256);

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256[] memory _balances
    ) external view returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy,
        address _receiver
    ) external returns (uint256);

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy,
        address _receiver
    ) external returns (uint256);

    function remove_liquidity(uint256 _burn_amount, uint256[] memory _min_amounts) external returns (uint256[] memory);

    function remove_liquidity(
        uint256 _burn_amount,
        uint256[] memory _min_amounts,
        address _receiver
    ) external returns (uint256[] memory);

    function remove_liquidity_imbalance(uint256[] memory _amounts, uint256 _max_burn_amount) external returns (uint256);

    function remove_liquidity_imbalance(
        uint256[] memory _amounts,
        uint256 _max_burn_amount,
        address _receiver
    ) external returns (uint256);

    function calc_withdraw_one_coin(uint256 _burn_amount, int128 i) external view returns (uint256);

    function calc_withdraw_one_coin(
        uint256 _burn_amount,
        int128 i,
        bool _previous
    ) external view returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _burn_amount,
        int128 i,
        uint256 _min_received
    ) external returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _burn_amount,
        int128 i,
        uint256 _min_received,
        address _receiver
    ) external returns (uint256);

    function admin_balances(uint256 i) external view returns (uint256);

    function withdraw_admin_fees() external;
}