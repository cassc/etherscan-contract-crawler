// SPDX-License-Identifier: MIT

pragma solidity ^0.7.2;
pragma experimental ABIEncoderV2;

interface ICurveZap {
  function add_liquidity(address pool, uint256[4] memory amounts, uint256 minAmount) external;

  function remove_liquidity_one_coin(address pool, uint256 _token_amount, int128 i, uint256 _minAmount) external;
  
}