// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

// Not extending ICurvePool, because get_dy() and exchange() are incompatible
interface ICurveCryptoPool {
    function future_A_gamma_time() external returns (uint256);
    function token() external view returns (address);
    function balances(uint256 i) external view returns (uint256);
    function D() external returns (uint256);
    function get_dy(uint256 i, uint256 j, uint256 dx) external view returns (uint256);
    function price_scale() external view returns (uint256);
    function lp_price() external view returns (uint256);
    function price_oracle() external view returns (uint256);
    function calc_token_amount(uint256[2] memory amounts) external view returns (uint256);

    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external returns (uint256);
    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount) external returns (uint256);
    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount, bool use_eth, address receiver) external returns (uint256 mint_amount);
    function remove_liquidity(uint256 burn_amount, uint256[2] memory min_amounts) external;
}