// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

interface ICurvePool {
  function get_dy(
    int128,
    int128,
    uint256
  ) external view returns (uint256);

  function get_dy(
    uint256,
    uint256,
    uint256
  ) external view returns (uint256);

  function get_dy_underlying(
    int128,
    int128,
    uint256
  ) external view returns (uint256);

  function get_dy_underlying(
    uint256,
    uint256,
    uint256
  ) external view returns (uint256);

  function exchange(
    int128,
    int128,
    uint256,
    uint256
  ) external;

  function exchange(
    uint256,
    uint256,
    uint256,
    uint256
  ) external;

  function exchange_underlying(
    int128,
    int128,
    uint256,
    uint256
  ) external;

  function exchange_underlying(
    uint256,
    uint256,
    uint256,
    uint256
  ) external;

  function coins(int128) external view returns (address);

  function coins(int256) external view returns (address);

  function coins(uint128) external view returns (address);

  function coins(uint256) external view returns (address);

  function underlying_coins(int128) external view returns (address);

  function underlying_coins(uint128) external view returns (address);

  function underlying_coins(int256) external view returns (address);

  function underlying_coins(uint256) external view returns (address);
}