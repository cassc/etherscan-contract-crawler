// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// this interface doesn't wok with 3Pool as it doesn't return anything on add_liquidity, remove_liquidity_one_coin
//solhint-disable
interface IStableSwapPool is IERC20 {
    function A() external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function calc_token_amount(uint256[3] memory amounts, bool deposit) external view returns (uint256);

    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount) external returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function remove_liquidity(uint256 _amount, uint256[3] memory min_amounts) external;

    function remove_liquidity_imbalance(uint256[3] memory amounts, uint256 max_burn_amount) external;

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external returns (uint256);
}