// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Kind 1
// Example v0.2.4 tripool (stables)
// See https://etherscan.io/address/0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7
interface ICurvePoolKind1 {
  function coins(uint256 index) external view returns (address);

  function base_coins(uint256 index) external view returns (address);

  function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external payable;

  function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external payable;
}

// Kind 2
// Example v0.2.8, Stableswap, v0.2.5 Curve GUSD Metapool
// See https://etherscan.io/address/0xdc24316b9ae028f1497c275eb9192a3ea0f67022
interface ICurvePoolKind2 {
  function coins(uint256 index) external view returns (address);

  function base_coins(uint256 index) external view returns (address);

  // 0x3df02124
  function exchange(
    int128 i,
    int128 j,
    uint256 dx,
    uint256 min_dy
  ) external payable returns (uint256);

  function exchange_underlying(
    int128 i,
    int128 j,
    uint256 dx,
    uint256 min_dy
  ) external payable returns (uint256);
}

// Kind 3
// Example v0.3.0, "# EUR/3crv pool where 3crv is _second_, not first"
// See https://etherscan.io/address/0x5D0F47B32fDd343BfA74cE221808e2abE4A53827
// NOTE: This contract has an `exchange_underlying` with a receiver also
interface ICurvePoolKind3 {
  function coins(uint256 index) external view returns (address);

  function underlying_coins(uint256 index) external view returns (address);

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
}