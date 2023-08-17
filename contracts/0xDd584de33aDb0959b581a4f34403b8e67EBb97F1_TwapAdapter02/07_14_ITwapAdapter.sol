// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.5.0;

import "./IUint256Oracle.sol";

interface ITwapAdapter is IUint256Oracle {
  function getTwapX96(address uniswapV3Pool, uint32 twapInterval) external view returns (uint256 priceX96);
  function getTwapX96(address uniswapV3Pool, uint32 twapIntervalFrom, uint32 twapIntervalTo) external view returns (uint256 priceX96);
  function getTwapX96(address uniswapV3Pool, uint32[] memory secondsAgos) external view returns (uint256 priceX96);
  function getPriceX96FromSqrtPriceX96(uint160 sqrtPriceX96) external pure returns (uint256 priceX96);
}