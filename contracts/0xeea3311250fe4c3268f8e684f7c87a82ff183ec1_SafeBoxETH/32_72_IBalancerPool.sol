pragma solidity 0.6.12;

interface IBalancerPool {
  function getFinalTokens() external view returns (address[] memory);

  function getNormalizedWeight(address token) external view returns (uint);

  function getSwapFee() external view returns (uint);

  function getNumTokens() external view returns (uint);

  function getBalance(address token) external view returns (uint);

  function totalSupply() external view returns (uint);

  function joinPool(uint poolAmountOut, uint[] calldata maxAmountsIn) external;

  function swapExactAmountOut(
    address tokenIn,
    uint maxAmountIn,
    address tokenOut,
    uint tokenAmountOut,
    uint maxPrice
  ) external returns (uint tokenAmountIn, uint spotPriceAfter);

  function joinswapExternAmountIn(
    address tokenIn,
    uint tokenAmountIn,
    uint minPoolAmountOut
  ) external returns (uint poolAmountOut);

  function exitPool(uint poolAmoutnIn, uint[] calldata minAmountsOut) external;

  function exitswapExternAmountOut(
    address tokenOut,
    uint tokenAmountOut,
    uint maxPoolAmountIn
  ) external returns (uint poolAmountIn);
}