// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface ICurveFi {
  function add_liquidity(uint256[2] calldata amounts, uint256 idx) external;

  function remove_liquidity_one_coin(
    uint256,
    int128,
    uint256
  ) external;
}