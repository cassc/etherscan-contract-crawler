// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

interface Curve3Pool {
  function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amounts) external;

  function remove_liquidity_one_coin(
    uint256 burn_amount,
    int128 i,
    uint256 min_amount
  ) external;

  function get_virtual_price() external view returns (uint256);

  function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

  function coins(uint256 i) external view returns (address);

  function calc_token_amount(uint256[3] calldata amounts, bool deposit) external view returns (uint256);

  function exchange(
    int128 i,
    int128 j,
    uint256 dx,
    uint256 min_dy
  ) external;
}