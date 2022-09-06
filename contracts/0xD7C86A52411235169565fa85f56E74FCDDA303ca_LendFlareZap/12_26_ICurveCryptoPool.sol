// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

// solhint-disable func-name-mixedcase, var-name-mixedcase

/// @dev This is the interface of Curve Crypto Pools (including Factory Pool), examples:
/// + cvxeth: https://curve.fi/cvxeth
/// + crveth: https://curve.fi/crveth
/// + eursusd: https://curve.fi/eursusd
/// + teth: https://curve.fi/teth
/// + spelleth: https://curve.fi/spelleth

/// + FXS/ETH: https://curve.fi/factory-crypto/3
/// + YFI/ETH: https://curve.fi/factory-crypto/8
/// + AAVE/palStkAAVE: https://curve.fi/factory-crypto/9
/// + DYDX/ETH: https://curve.fi/factory-crypto/10
/// + SDT/ETH: https://curve.fi/factory-crypto/11
/// + BTRFLY/ETH: https://curve.fi/factory-crypto/17
/// + cvxFXS/FXS: https://curve.fi/factory-crypto/18
interface ICurveCryptoPool {
  function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount) external payable returns (uint256);

  function calc_token_amount(uint256[2] memory amounts) external view returns (uint256);

  function remove_liquidity_one_coin(
    uint256 token_amount,
    uint256 i,
    uint256 min_amount
  ) external returns (uint256);

  function calc_withdraw_one_coin(uint256 token_amount, uint256 i) external view returns (uint256);

  function exchange(
    uint256 i,
    uint256 j,
    uint256 dx,
    uint256 min_dy
  ) external payable returns (uint256);

  function exchange_underlying(
    uint256 i,
    uint256 j,
    uint256 dx,
    uint256 min_dy
  ) external payable returns (uint256);

  function get_dy(
    uint256 i,
    uint256 j,
    uint256 dx
  ) external view returns (uint256);

  function coins(uint256 index) external view returns (address);
}

/// @dev This is the interface of Zap Contract for Curve Meta Crypto Pools, examples:
/// + eurtusd: https://curve.fi/eurtusd
/// + xautusd: https://curve.fi/xautusd
interface IZapCurveMetaCryptoPool {
  function add_liquidity(uint256[4] memory amounts, uint256 min_mint_amount) external returns (uint256);

  function calc_token_amount(uint256[4] memory amounts) external view returns (uint256);

  function remove_liquidity_one_coin(
    uint256 token_amount,
    uint256 i,
    uint256 min_amount
  ) external returns (uint256);

  function calc_withdraw_one_coin(uint256 token_amount, uint256 i) external view returns (uint256);

  function exchange_underlying(
    uint256 i,
    uint256 j,
    uint256 dx,
    uint256 min_dy
  ) external returns (uint256);

  function get_dy_underlying(
    uint256 i,
    uint256 j,
    uint256 dx
  ) external view returns (uint256);

  function coins(uint256 index) external view returns (address);

  function underlying_coins(uint256 index) external view returns (address);

  function token() external view returns (address);

  function base_pool() external view returns (address);

  function pool() external view returns (address);
}

/// @dev This is the interface of Curve Tri Crypto Pools, examples:
/// + tricrypto2: https://curve.fi/tricrypto2
/// + tricrypto: https://curve.fi/tricrypto
interface ICurveTriCryptoPool {
  function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount) external;

  function calc_token_amount(uint256[3] memory amounts, bool deposit) external view returns (uint256);

  function remove_liquidity_one_coin(
    uint256 token_amount,
    uint256 i,
    uint256 min_amount
  ) external;

  function calc_withdraw_one_coin(uint256 token_amount, uint256 i) external view returns (uint256);

  function exchange(
    uint256 i,
    uint256 j,
    uint256 dx,
    uint256 min_dy,
    bool use_eth
  ) external;

  function get_dy(
    uint256 i,
    uint256 j,
    uint256 dx
  ) external view returns (uint256);

  function token() external view returns (address);

  function coins(uint256 index) external returns (address);
}