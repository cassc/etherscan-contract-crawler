// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

// solhint-disable var-name-mixedcase, func-name-mixedcase

/// @dev This is the interface of Curve Factory Meta Pool (with 3pool or sbtc), examples:
/// + mim: https://curve.fi/mim
/// + frax: https://curve.fi/frax
/// + tusd: https://curve.fi/tusd
/// + ousd + 3crv: https://curve.fi/factory/9
/// + fei + 3crv: https://curve.fi/factory/11
/// + dola + 3crv: https://curve.fi/factory/27
/// + ust + 3crv: https://curve.fi/factory/53
/// + usdp + 3crv: https://curve.fi/factory/59
/// + wibBTC + crvRenWSBTC: https://curve.fi/factory/60
/// + bean + 3crv: https://curve.fi/factory/81
/// + usdv + 3crv: https://curve.fi/factory/82
interface ICurveFactoryMetaPool {
  function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount) external returns (uint256);

  function calc_token_amount(uint256[2] memory amounts, bool is_deposit) external view returns (uint256);

  function remove_liquidity_one_coin(
    uint256 token_amount,
    int128 i,
    uint256 min_amount
  ) external returns (uint256);

  function calc_withdraw_one_coin(uint256 token_amount, int128 i) external view returns (uint256);

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
}

interface ICurveDepositZap {
  function add_liquidity(
    address _pool,
    uint256[4] memory _deposit_amounts,
    uint256 _min_mint_amount
  ) external returns (uint256);

  function calc_token_amount(
    address _pool,
    uint256[4] memory _amounts,
    bool _is_deposit
  ) external view returns (uint256);

  function remove_liquidity_one_coin(
    address _pool,
    uint256 _burn_amount,
    int128 i,
    uint256 _min_amount
  ) external returns (uint256);

  function calc_withdraw_one_coin(
    address _pool,
    uint256 _token_amount,
    int128 i
  ) external view returns (uint256);
}