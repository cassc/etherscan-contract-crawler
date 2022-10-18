// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface ICurvePool {
    function add_liquidity(uint256[2] memory amounts, uint256 min_mint) external payable returns (uint256); 
    function token() external returns (address);
    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 _min_amount) external returns (uint256);
}