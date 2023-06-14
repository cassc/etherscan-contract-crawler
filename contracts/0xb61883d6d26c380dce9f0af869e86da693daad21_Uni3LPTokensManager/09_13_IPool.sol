// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

interface IPool {
  function token1() external view returns (address);

  function token0() external view returns (address);

  function fee() external view returns (uint24);

  function initialize(uint160 sqrtPriceX96) external;

  function slot0()
    external
    view
    returns (
      uint160 sqrtPriceX96,
      int24 tick,
      uint16 observationIndex,
      uint16 observationCardinality,
      uint16 observationCardinalityNext,
      uint8 feeProtocol,
      bool unlocked
    );

  function tickSpacing() external view returns (int24);
}