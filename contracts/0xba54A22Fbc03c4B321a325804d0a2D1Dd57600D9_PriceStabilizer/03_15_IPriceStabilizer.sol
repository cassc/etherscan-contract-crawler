// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../external/AggregatorV3Interface.sol";

interface IPriceStabilizer {
  struct PoolInfo {
    address reserve;
    address stablecoin;
    address pool;
    address oracle;
  }

  function initializePool(address pool, address oracle) external;

  function updateOracle(address pool, address oracle) external;

  function updatePrice(
    address pool,
    uint256 amountIn,
    uint256 minAmountOut,
    bool stablecoinForReserve
  ) external returns (uint256 poolPrice, uint256 oraclePrice);

  event InitializedPool(address indexed pool, address indexed oracle);
  event UpdatedOracle(address indexed pool, address indexed oracle);
  event UpdatePrice(
    address indexed pool,
    uint256 amountIn,
    uint256 minAmountOut,
    bool stablecoinForReserve
  );
}