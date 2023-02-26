// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

interface IUniFactoryV3 {
  event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);
  event OwnerChanged(address indexed oldOwner, address indexed newOwner);
  event PoolCreated(
    address indexed token0,
    address indexed token1,
    uint24 indexed fee,
    int24 tickSpacing,
    address pool
  );

  function createPool(
    address tokenA,
    address tokenB,
    uint24 fee
  ) external returns (address pool);

  function enableFeeAmount(uint24 fee, int24 tickSpacing) external;

  function feeAmountTickSpacing(uint24) external view returns (int24);

  function getPool(
    address,
    address,
    uint24
  ) external view returns (address);

  function owner() external view returns (address);

  function parameters()
  external
  view
  returns (
    address factory,
    address token0,
    address token1,
    uint24 fee,
    int24 tickSpacing
  );

  function setOwner(address _owner) external;
}