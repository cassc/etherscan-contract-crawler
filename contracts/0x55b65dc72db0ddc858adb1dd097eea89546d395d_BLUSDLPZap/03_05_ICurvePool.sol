// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface ICurvePool is IERC20 { 
    function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount) external returns (uint256 mint_amount);

    function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount, address _receiver) external returns (uint256 mint_amount);

    function remove_liquidity(uint256 burn_amount, uint256[2] memory _min_amounts) external;

    function remove_liquidity_one_coin(uint256 _burn_amount, int128 i, uint256 _min_received) external;

    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy, address _receiver) external returns (uint256);

    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy, address _receiver) external returns (uint256);

    function calc_withdraw_one_coin(uint256 _burn_amount, int128 i) external view returns (uint256);

    function calc_token_amount(uint256[2] memory _amounts, bool _is_deposit) external view returns (uint256);

    function balances(uint256 arg0) external view returns (uint256);

    function token() external view returns (address);

    function totalSupply() external view returns (uint256);

    function get_dy(int128 i,int128 j, uint256 dx) external view returns (uint256);

    function get_dy_underlying(int128 i,int128 j, uint256 dx) external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function fee() external view returns (uint256);

    function D() external returns (uint256);

    function future_A_gamma_time() external returns (uint256);
}