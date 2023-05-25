// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

// solhint-disable var-name-mixedcase, func-name-mixedcase

interface ICurveYPoolSwap {
  function exchange(
    int128 i,
    int128 j,
    uint256 dx,
    uint256 min_dy
  ) external;

  function exchange_underlying(
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

  function underlying_coins(uint256 index) external view returns (address);
}

interface ICurveYPoolDeposit {
  function remove_liquidity_one_coin(
    uint256 _token_amount,
    int128 i,
    uint256 _min_amount,
    bool donate_dust
  ) external;

  function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

  function token() external view returns (address);

  function curve() external view returns (address);

  function coins(uint256 index) external view returns (address);

  function underlying_coins(uint256 index) external view returns (address);

  function coins(int128 index) external view returns (address);

  function underlying_coins(int128 index) external view returns (address);
}

// solhint-disable var-name-mixedcase, func-name-mixedcase
/// @dev This is the interface of Curve yearn-style Pool with 2 tokens, examples:
/// + compound: https://curve.fi/compound
interface ICurveY2PoolDeposit is ICurveYPoolDeposit {
  function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount) external;
}

interface ICurveY2PoolSwap is ICurveYPoolSwap {
  function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount) external;
}

/// @dev This is the interface of Curve yearn-style Pool with 3 tokens, examples:
/// usdt: https://curve.fi/usdt
interface ICurveY3PoolDeposit is ICurveYPoolDeposit {
  function add_liquidity(uint256[3] memory _amounts, uint256 _min_mint_amount) external;
}

interface ICurveY3PoolSwap is ICurveYPoolSwap {
  function add_liquidity(uint256[3] memory _amounts, uint256 _min_mint_amount) external;
}

/// @dev This is the interface of Curve yearn-style Pool with 4 tokens, examples:
/// + pax: https://curve.fi/pax
/// + y: https://curve.fi/iearn
/// + busd: https://curve.fi/busd
/// + susd v2: https://curve.fi/susdv2
interface ICurveY4PoolDeposit is ICurveYPoolDeposit {
  function add_liquidity(uint256[4] memory _amounts, uint256 _min_mint_amount) external;
}

interface ICurveY4PoolSwap is ICurveYPoolSwap {
  function add_liquidity(uint256[4] memory _amounts, uint256 _min_mint_amount) external;
}