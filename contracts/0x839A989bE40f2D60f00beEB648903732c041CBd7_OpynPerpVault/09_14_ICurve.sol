// SPDX-License-Identifier: MIT
pragma solidity ^0.7.2;
pragma experimental ABIEncoderV2;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface ICurve is IERC20 {
  function add_liquidity(uint256[4] memory amounts, uint256 minAmount) external;

  function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 _minAmount) external;

  function get_virtual_price() external view returns (uint256);

  function calc_token_amount(uint256[4] memory amounts, bool isDeposit) external view returns (uint256);
}