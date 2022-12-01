// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IStablecoinEngine {
  struct StablecoinPoolInfo {
    address reserve;
    address stablecoin;
    address pool;
    bool stablecoinIsToken0;
  }

  function pools(address reserve, address stablecoin)
    external
    view
    returns (address pool);

  function poolsInfo(address _pool)
    external
    view
    returns (
      address reserve,
      address stablecoin,
      address pool,
      bool stablecoinIsToken0
    );

  function initializeStablecoin(
    address reserve,
    address stablecoin,
    uint256 initialReserveAmount,
    uint256 initialStablecoinAmount
  ) external returns (address poolAddress);

  function addLiquidity(
    address pool,
    uint256 reserveAmountDesired,
    uint256 stablecoinAmountDesired,
    uint256 reserveAmountMin,
    uint256 stablecoinAmountMin
  ) external returns (uint256 liquidity);

  function removeLiquidity(
    address pool,
    uint256 liquidity,
    uint256 minimumReserveAmount,
    uint256 minimumStablecoinAmount
  ) external returns (uint256 reserveAmount, uint256 stablecoinAmount);

  function swap(
    address poolAddr,
    uint256 amountIn,
    uint256 minAmountOut,
    bool stablecoinForReserve
  ) external returns (uint256 amountOut);

  function mint(
    address stablecoin,
    address to,
    uint256 amount
  ) external;

  function calculateAmounts(
    address poolAddr,
    uint256 reserveAmountDesired,
    uint256 stablecoinAmountDesired,
    uint256 reserveAmountMin,
    uint256 stablecoinAmountMin
  ) external view returns (uint256 reserveAmount, uint256 stablecoinAmount);

  function getReserves(address poolAddr)
    external
    view
    returns (uint256 stablecoinReserve, uint256 reserveReserve);

  event PoolAdded(
    address indexed reserve,
    address indexed stablecoin,
    address indexed pool
  );
  event LiquidityAdded(
    address indexed pool,
    uint256 liquidity,
    uint256 reserve,
    uint256 stablecoin
  );
  event LiquidityRemoved(
    address indexed pool,
    uint256 liquidity,
    uint256 reserve,
    uint256 stablecoin
  );
  event Swap(
    address indexed pool,
    uint256 amountIn,
    uint256 amountOut,
    bool stablecoinForReserve
  );
}