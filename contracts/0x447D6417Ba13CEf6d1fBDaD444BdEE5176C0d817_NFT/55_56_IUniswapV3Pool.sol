// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface IUniswapV3Pool {
  function initialize(uint160 sqrtPriceX96) external;

  function token0() external view returns (address);

  function token1() external view returns (address);

  function fee() external view returns (uint24);

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

  function positions(bytes32 key)
    external
    view
    returns (
      uint128 _liquidity,
      uint256 feeGrowthInside0LastX128,
      uint256 feeGrowthInside1LastX128,
      uint128 tokensOwed0,
      uint128 tokensOwed1
    );

  function observe(uint32[] calldata secondsAgos)
    external
    view
    returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);
}