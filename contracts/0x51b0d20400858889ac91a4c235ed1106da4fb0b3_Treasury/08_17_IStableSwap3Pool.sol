// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

interface IStableSwap3Pool {
    function calc_token_amount(uint256[3] calldata _amounts, bool _is_deposit) external returns (uint256);
    function add_liquidity(uint256[3] calldata _amounts, uint256 _min_mint_amount) external;
    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external returns (uint256);
    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 _min_amount) external;
    function get_virtual_price() external returns (uint256);
    function coins(uint256 i) external returns (address);
}