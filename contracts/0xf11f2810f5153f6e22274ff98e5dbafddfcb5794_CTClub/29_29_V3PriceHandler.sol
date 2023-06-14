// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import '@uniswap/v3-core/contracts/libraries/FixedPoint96.sol';
import '@uniswap/v3-core/contracts/libraries/FullMath.sol';
import './interfaces/IERC20Metadata.sol';

contract V3PriceHandler {
  uint32 constant TWAP_INTERVAL = 5 minutes;
  address constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address constant WETH9_USDC_POOL = 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640;

  function _getUSDPriceX96(address _pool) internal view returns (uint256) {
    uint256 _priceWETH9PerTokenX96 = _priceAdjustedX96(
      IUniswapV3Pool(_pool),
      WETH9
    );
    address _token0 = IUniswapV3Pool(WETH9_USDC_POOL).token0();
    address _token1 = IUniswapV3Pool(WETH9_USDC_POOL).token1();
    uint256 _priceUSDCPerWETH9X96 = _priceAdjustedX96(
      IUniswapV3Pool(WETH9_USDC_POOL),
      _token0 == WETH9 ? _token1 : _token0
    );
    return (_priceUSDCPerWETH9X96 * _priceWETH9PerTokenX96) / FixedPoint96.Q96;
  }

  function _getSqrtPriceX96(
    IUniswapV3Pool _pool
  ) internal view returns (uint160) {
    uint32[] memory secondsAgo = new uint32[](2);
    secondsAgo[0] = TWAP_INTERVAL;
    secondsAgo[1] = 0;
    (int56[] memory tickCumulatives, ) = _pool.observe(secondsAgo);
    return
      TickMath.getSqrtRatioAtTick(
        int24((tickCumulatives[1] - tickCumulatives[0]) / TWAP_INTERVAL)
      );
  }

  function _priceAdjustedX96(
    IUniswapV3Pool _pool,
    address _numerator
  ) internal view returns (uint256) {
    address _token1 = _pool.token1();
    uint8 _decimals0 = IERC20Metadata(_pool.token0()).decimals();
    uint8 _decimals1 = IERC20Metadata(_token1).decimals();
    uint160 _sqrtPriceX96 = _getSqrtPriceX96(_pool);
    uint256 _priceX96 = FullMath.mulDiv(
      _sqrtPriceX96,
      _sqrtPriceX96,
      FixedPoint96.Q96
    );
    uint256 _correctedPriceX96 = _token1 == _numerator
      ? _priceX96
      : FixedPoint96.Q96 ** 2 / _priceX96;
    return
      _token1 == _numerator
        ? (_correctedPriceX96 * 10 ** _decimals0) / 10 ** _decimals1
        : (_correctedPriceX96 * 10 ** _decimals1) / 10 ** _decimals0;
  }
}