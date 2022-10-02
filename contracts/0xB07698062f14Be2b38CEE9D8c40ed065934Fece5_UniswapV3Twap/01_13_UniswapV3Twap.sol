// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {OracleLibrary} from "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";
import {IERC20Metadata} from "./interfaces/IERC20Metadata.sol";
import {IUniswapV3Twap} from "./interfaces/IUniswapV3Twap.sol";

contract UniswapV3Twap is IUniswapV3Twap {
  IUniswapV3Pool public immutable pool;
  address public owner;
  int24 public maxDeviation = 2;

  constructor(address _pool) {
    require(_pool != address(0), "!pool");
    pool = IUniswapV3Pool(_pool);
    owner = msg.sender;
  }

  function estimateAmountOut(
    address tokenIn,
    uint128 amountIn,
    uint32 secondsAgo
  ) external view override returns (uint amountOut, uint8 decimalsOut) {
    address token0 = pool.token0();
    address token1 = pool.token1();
    require(tokenIn == token0 || tokenIn == token1, "!token");
    address tokenOut = tokenIn == token0 ? token1 : token0;
    (int24 twapTick,) = OracleLibrary.consult(address(pool), secondsAgo);
    (int24 earlyTwapTick,) = OracleLibrary.consult(address(pool), secondsAgo + 5 minutes);
    int24 deviation = earlyTwapTick > twapTick ? earlyTwapTick - twapTick : twapTick - earlyTwapTick;
    int24 needTick = deviation <= maxDeviation ? twapTick : earlyTwapTick;
    amountOut = OracleLibrary.getQuoteAtTick(needTick, amountIn, tokenIn, tokenOut);
    decimalsOut = IERC20Metadata(tokenOut).decimals();
  }

  function setMaxDeviation(int24 _maxDeviation) external onlyOwner {
    maxDeviation = _maxDeviation;
  }

  function ownerTransfer(address newOwner) external onlyOwner {
    owner = newOwner;
  }

  modifier onlyOwner {
    require(msg.sender == owner, "!owner");
    _;
  }
}