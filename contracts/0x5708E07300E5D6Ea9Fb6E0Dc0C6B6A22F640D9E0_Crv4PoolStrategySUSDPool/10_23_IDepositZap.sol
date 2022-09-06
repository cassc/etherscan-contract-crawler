// SPDX-License-Identifier: MIT
/* solhint-disable */
pragma solidity 0.8.9;

interface IDepositZap4x {
    function calc_token_amount(
        address _pool,
        uint256[4] memory _amounts,
        bool is_deposit
    ) external view returns (uint256);

    function add_liquidity(
        address _pool,
        uint256[4] memory _amounts,
        uint256 _min_mint_amount
    ) external;

    function remove_liquidity(
        address _pool,
        uint256 _amount,
        uint256[4] memory _min_amounts
    ) external;

    function remove_liquidity_one_coin(
        address _pool,
        uint256 _token_amount,
        int128 i,
        uint256 _min_amount
    ) external;

    function calc_withdraw_one_coin(
        address _pool,
        uint256 _token_amount,
        int128 i
    ) external view returns (uint256);
}