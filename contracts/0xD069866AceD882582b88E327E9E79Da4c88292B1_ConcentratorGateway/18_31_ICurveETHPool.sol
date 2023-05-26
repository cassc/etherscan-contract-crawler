// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

// solhint-disable func-name-mixedcase, var-name-mixedcase

/// @dev This is the interface of Curve ETH Pools (including Factory Pool), examples:
/// + steth: https://curve.fi/steth
/// + seth: https://curve.fi/seth
/// + reth: https://curve.fi/reth
/// + ankreth: https://curve.fi/ankreth
/// + alETH [Factory]: https://curve.fi/factory/38
/// + Ankr Reward-Earning Staked ETH [Factory]: https://curve.fi/factory/56
interface ICurveETHPool {
  function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount) external payable returns (uint256);

  function calc_token_amount(uint256[2] memory amounts, bool is_deposit) external view returns (uint256);

  function remove_liquidity_one_coin(
    uint256 _token_amount,
    int128 i,
    uint256 _min_amount
  ) external returns (uint256);

  function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

  function exchange(
    int128 i,
    int128 j,
    uint256 dx,
    uint256 min_dy
  ) external payable returns (uint256);

  function get_dy(
    int128 i,
    int128 j,
    uint256 dx
  ) external view returns (uint256);

  function coins(uint256 index) external view returns (address);

  function lp_token() external view returns (address);
}