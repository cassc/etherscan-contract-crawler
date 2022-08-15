// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface ICurveFi {
  function add_liquidity(
    uint256[3] calldata amounts,
    uint256 min_amount,
    bool use_underlying
  ) external returns (uint256);

  function remove_liquidity_one_coin(
    uint256,
    int128,
    uint256,
    bool
  ) external returns (uint256);
}