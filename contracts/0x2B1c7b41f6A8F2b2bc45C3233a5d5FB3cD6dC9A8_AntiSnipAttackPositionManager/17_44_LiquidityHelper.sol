// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.9;
pragma abicoder v2;

import {LiquidityMath} from '../libraries/LiquidityMath.sol';
import {PoolAddress} from '../libraries/PoolAddress.sol';
import {TickMath} from '../../libraries/TickMath.sol';

import {IPool} from '../../interfaces/IPool.sol';
import {IFactory} from '../../interfaces/IFactory.sol';
import {IMintCallback} from '../../interfaces/callback/IMintCallback.sol';

import {RouterTokenHelper} from './RouterTokenHelper.sol';

abstract contract LiquidityHelper is IMintCallback, RouterTokenHelper {
  constructor(address _factory, address _WETH) RouterTokenHelper(_factory, _WETH) {}

  struct AddLiquidityParams {
    address token0;
    address token1;
    uint24 fee;
    address recipient;
    int24 tickLower;
    int24 tickUpper;
    int24[2] ticksPrevious;
    uint256 amount0Desired;
    uint256 amount1Desired;
    uint256 amount0Min;
    uint256 amount1Min;
  }

  struct CallbackData {
    address token0;
    address token1;
    uint24 fee;
    address source;
  }

  function mintCallback(
    uint256 deltaQty0,
    uint256 deltaQty1,
    bytes calldata data
  ) external override {
    CallbackData memory callbackData = abi.decode(data, (CallbackData));
    require(callbackData.token0 < callbackData.token1, 'LiquidityHelper: wrong token order');
    address pool = address(_getPool(callbackData.token0, callbackData.token1, callbackData.fee));
    require(msg.sender == pool, 'LiquidityHelper: invalid callback sender');
    if (deltaQty0 > 0)
      _transferTokens(callbackData.token0, callbackData.source, msg.sender, deltaQty0);
    if (deltaQty1 > 0)
      _transferTokens(callbackData.token1, callbackData.source, msg.sender, deltaQty1);
  }

  /// @dev Add liquidity to a pool given params
  /// @param params add liquidity params, token0, token1 should be in the correct order
  /// @return liquidity amount of liquidity has been minted
  /// @return amount0 amount of token0 that is needed
  /// @return amount1 amount of token1 that is needed
  /// @return feeGrowthInsideLast position manager's updated feeGrowthInsideLast value
  /// @return pool address of the pool
  function _addLiquidity(AddLiquidityParams memory params)
    internal
    returns (
      uint128 liquidity,
      uint256 amount0,
      uint256 amount1,
      uint256 feeGrowthInsideLast,
      IPool pool
    )
  {
    require(params.token0 < params.token1, 'LiquidityHelper: invalid token order');
    pool = _getPool(params.token0, params.token1, params.fee);

    // compute the liquidity amount
    {
      (uint160 currentSqrtP, , , ) = pool.getPoolState();
      uint160 lowerSqrtP = TickMath.getSqrtRatioAtTick(params.tickLower);
      uint160 upperSqrtP = TickMath.getSqrtRatioAtTick(params.tickUpper);

      liquidity = LiquidityMath.getLiquidityFromQties(
        currentSqrtP,
        lowerSqrtP,
        upperSqrtP,
        params.amount0Desired,
        params.amount1Desired
      );
    }

    (amount0, amount1, feeGrowthInsideLast) = pool.mint(
      params.recipient,
      params.tickLower,
      params.tickUpper,
      params.ticksPrevious,
      liquidity,
      _callbackData(params.token0, params.token1, params.fee)
    );

    require(
      amount0 >= params.amount0Min && amount1 >= params.amount1Min,
      'LiquidityHelper: price slippage check'
    );
  }

  function _callbackData(
    address token0,
    address token1,
    uint24 fee
  ) internal view returns (bytes memory) {
    return
      abi.encode(CallbackData({token0: token0, token1: token1, fee: fee, source: msg.sender}));
  }

  /**
   * @dev Returns the pool address for the requested token pair swap fee
   * Because the function calculates it instead of fetching the address from the factory,
   * the returned pool address may not be in existence yet
   */
  function _getPool(
    address tokenA,
    address tokenB,
    uint24 fee
  ) internal view returns (IPool) {
    return IPool(PoolAddress.computeAddress(factory, tokenA, tokenB, fee, poolInitHash));
  }
}