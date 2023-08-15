// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title ISwapper
 *
 * @author Fujidao Labs
 *
 * @notice  Defines the interface for routers to perform token swaps with DEX protocols.
 *
 * @dev Implementation inheriting this interface should be permisionless.
 */

interface ISwapper {
  /**
   * @notice Swap tokens at exchange.
   *
   * @param assetIn address of the ERC-20 token to swap from
   * @param assetOut address of the ERC-20 token to swap to
   * @param amountIn that will be pulled from msg.sender
   * @param amountOut of `assetOut` expected after the swap
   * @param receiver of the `amountOut` tokens
   * @param sweeper who receives the leftovers `assetIn` tokens after swap
   * @param minSweepOut  amount of `assetIn` leftover expected after swap
   *
   * @dev Slippage is controlled through `minSweepOut`. If `minSweepOut` is 0,
   * the slippage check gets skipped.
   */
  function swap(
    address assetIn,
    address assetOut,
    uint256 amountIn,
    uint256 amountOut,
    address receiver,
    address sweeper,
    uint256 minSweepOut
  )
    external;

  /**
   * @notice Estimate the amount of `assetIn` required for `swap()`.
   *
   * @param assetIn address of the ERC-20 token to swap from
   * @param assetOut address of the ERC-20 token to swap to
   * @param amountOut expected amount of `assetOut` after the swap
   */
  function getAmountIn(
    address assetIn,
    address assetOut,
    uint256 amountOut
  )
    external
    view
    returns (uint256 amountIn);

  /**
   * @notice Estimate the amount of `assetOut` received after swap
   *
   * @param assetIn address of the ERC-20 token to swap from
   * @param assetOut address of the ERC-20 token to swap to
   * @param amountIn of `assetIn` to perform swap
   */
  function getAmountOut(
    address assetIn,
    address assetOut,
    uint256 amountIn
  )
    external
    view
    returns (uint256 amountOut);
}