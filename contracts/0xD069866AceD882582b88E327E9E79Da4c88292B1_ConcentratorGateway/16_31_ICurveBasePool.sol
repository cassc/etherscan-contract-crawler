// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

// solhint-disable var-name-mixedcase, func-name-mixedcase

interface ICurveBasePool {
  function remove_liquidity_one_coin(
    uint256 _token_amount,
    int128 i,
    uint256 min_amount
  ) external;

  function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

  function exchange(
    int128 i,
    int128 j,
    uint256 dx,
    uint256 min_dy
  ) external;

  function get_dy(
    int128 i,
    int128 j,
    uint256 dx
  ) external view returns (uint256);

  function get_dy_underlying(
    int128 i,
    int128 j,
    uint256 dx
  ) external view returns (uint256);

  function coins(uint256 index) external view returns (address);

  // ren and sbtc pool
  function coins(int128 index) external view returns (address);
}

/// @dev This is the interface of Curve base-style Pool with 2 tokens, examples:
/// hbtc: https://curve.fi/hbtc
/// ren: https://curve.fi/ren
/// eurs: https://www.curve.fi/eurs
interface ICurveBase2Pool {
  function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount) external;

  function calc_token_amount(uint256[2] memory amounts, bool deposit) external view returns (uint256);
}

/// @dev This is the interface of Curve base-style Pool with 3 tokens, examples:
/// sbtc: https://curve.fi/sbtc
/// 3pool: https://curve.fi/3pool
interface ICurveBase3Pool {
  function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount) external;

  function calc_token_amount(uint256[3] memory amounts, bool deposit) external view returns (uint256);
}

/// @dev This is the interface of Curve base-style Pool with 4 tokens, examples:
interface ICurveBase4Pool {
  function add_liquidity(uint256[4] memory amounts, uint256 min_mint_amount) external;

  function calc_token_amount(uint256[4] memory amounts, bool deposit) external view returns (uint256);
}