// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

interface IBasePositionManager {
  struct Position {
    // the nonce for permits
    uint96 nonce;
    // the address that is approved for spending this token
    address operator;
    // the ID of the pool with which this token is connected
    uint80 poolId;
    // the tick range of the position
    int24 tickLower;
    int24 tickUpper;
    // the liquidity of the position
    uint128 liquidity;
    // the current rToken that the position owed
    uint256 rTokenOwed;
    // fee growth per unit of liquidity as of the last update to liquidity
    uint256 feeGrowthInsideLast;
  }

  struct PoolInfo {
    address token0;
    uint16 fee;
    address token1;
  }

  struct MintParams {
    address token0;
    address token1;
    uint24 fee;
    int24 tickLower;
    int24 tickUpper;
    int24[2] ticksPrevious;
    uint256 amount0Desired;
    uint256 amount1Desired;
    uint256 amount0Min;
    uint256 amount1Min;
    address recipient;
    uint256 deadline;
  }

  struct IncreaseLiquidityParams {
    uint256 tokenId;
    uint256 amount0Desired;
    uint256 amount1Desired;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
  }

  struct RemoveLiquidityParams {
    uint256 tokenId;
    uint128 liquidity;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
  }

  struct BurnRTokenParams {
    uint256 tokenId;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
  }

  function positions(
    uint256 tokenId
  ) external view returns (Position memory pos, PoolInfo memory info);

  function addressToPoolId(address pool) external view returns (uint80);

  function WETH() external view returns (address);

  function mint(
    MintParams calldata params
  )
    external
    payable
    returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

  function addLiquidity(
    IncreaseLiquidityParams calldata params
  )
    external
    payable
    returns (uint128 liquidity, uint256 amount0, uint256 amount1, uint256 additionalRTokenOwed);

  function removeLiquidity(
    RemoveLiquidityParams calldata params
  ) external returns (uint256 amount0, uint256 amount1, uint256 additionalRTokenOwed);

  function syncFeeGrowth(uint256 tokenId) external returns (uint256 additionalRTokenOwed);

  function burnRTokens(
    BurnRTokenParams calldata params
  ) external returns (uint256 rTokenQty, uint256 amount0, uint256 amount1);

  function transferAllTokens(address token, uint256 minAmount, address recipient) external payable;

  function unwrapWeth(uint256 minAmount, address recipient) external payable;
}