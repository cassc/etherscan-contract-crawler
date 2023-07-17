// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

interface ICurvePool {
  function add_liquidity(uint256[4] memory amounts, uint256 min_mint_amount) external payable;
  function get_virtual_price() external view returns (uint256);
  function admin_balances(uint256 i) external view returns (uint256);
}