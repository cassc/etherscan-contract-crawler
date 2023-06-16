// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

interface ITwap {
  /**
   * @notice Returns the amount out corresponding to the amount in for a given token using the moving average over time range [`block.timestamp` - [`windowSize`, `windowSize - periodSize * 2`], `block.timestamp`].
   * E.g. with a windowSize = 24hrs, periodSize = 6hrs.
   * [24hrs ago to 12hrs ago, now]
   * @dev Update must have been called for the bucket corresponding to the timestamp `now - windowSize`
   * @param tokenIn the address of the token we are offering
   * @param amountIn the quantity of tokens we are pricing
   * @param tokenOut the address of the token we want
   * @return amountOut the `tokenOut` amount corresponding to the `amountIn` for `tokenIn` over the time range
   */
  function consult(
    address tokenIn,
    uint256 amountIn,
    address tokenOut
  ) external view returns (uint256 amountOut);

  /**
   * @notice Checks if a particular pair can be updated
   * @param tokenA Token A of pair (any order)
   * @param tokenB Token B of pair (any order)
   * @return If an update call will succeed
   */
  function updateable(address tokenA, address tokenB)
    external
    view
    returns (bool);

  /**
   * @notice Update the cumulative price for the observation at the current timestamp. Each observation is updated at most once per epoch period.
   * @param tokenA the first token to create pair from
   * @param tokenB the second token to create pair from
   * @return if the observation was updated or not.
   */
  function update(address tokenA, address tokenB) external returns (bool);
}