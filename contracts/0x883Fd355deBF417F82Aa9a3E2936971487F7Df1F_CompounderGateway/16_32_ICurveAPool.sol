// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

// solhint-disable var-name-mixedcase, func-name-mixedcase

interface ICurveAPool {
  function remove_liquidity_one_coin(
    uint256 _token_amount,
    int128 i,
    uint256 _min_amount,
    bool _use_underlying
  ) external returns (uint256);

  function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

  function exchange(
    int128 i,
    int128 j,
    uint256 dx,
    uint256 min_dy
  ) external returns (uint256);

  function exchange_underlying(
    int128 i,
    int128 j,
    uint256 dx,
    uint256 min_dy
  ) external returns (uint256);

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

  function underlying_coins(uint256 index) external view returns (address);

  function lp_token() external view returns (address);
}

/// @dev This is the interface of Curve aave-style Pool with 2 tokens, examples:
/// + saave: https://curve.fi/saave
interface ICurveA2Pool is ICurveAPool {
  function add_liquidity(
    uint256[2] memory _amounts,
    uint256 _min_mint_amount,
    bool _use_underlying
  ) external returns (uint256);

  function calc_token_amount(uint256[2] memory amounts, bool is_deposit) external view returns (uint256);
}

/// @dev This is the interface of Curve aave-style Pool with 3 tokens, examples:
/// aave: https://curve.fi/aave
/// ironbank: https://curve.fi/ib
interface ICurveA3Pool is ICurveAPool {
  function add_liquidity(
    uint256[3] memory _amounts,
    uint256 _min_mint_amount,
    bool _use_underlying
  ) external returns (uint256);

  function calc_token_amount(uint256[3] memory amounts, bool is_deposit) external view returns (uint256);
}

/// @dev This is the interface of Curve aave-style Pool with 3 tokens, examples:
interface ICurveA4Pool is ICurveAPool {
  function add_liquidity(
    uint256[4] memory _amounts,
    uint256 _min_mint_amount,
    bool _use_underlying
  ) external returns (uint256);

  function calc_token_amount(uint256[4] memory amounts, bool is_deposit) external view returns (uint256);
}