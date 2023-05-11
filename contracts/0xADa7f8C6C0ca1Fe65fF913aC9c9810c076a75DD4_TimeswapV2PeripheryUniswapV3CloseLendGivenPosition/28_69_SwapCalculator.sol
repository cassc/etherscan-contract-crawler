// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.8;

import {StrikeConversion} from "@timeswap-labs/v2-library/contracts/StrikeConversion.sol";
import {Math} from "@timeswap-labs/v2-library/contracts/Math.sol";

import {UniswapImmutableState} from "./UniswapV3SwapCallback.sol";

import {UniswapV3FactoryLibrary} from "../libraries/UniswapV3Factory.sol";
import {UniswapV3PoolLibrary} from "../libraries/UniswapV3Pool.sol";

import {UniswapV3SwapParam, UniswapV3CalculateSwapParam, UniswapV3CalculateSwapGivenBalanceLimitParam} from "../structs/SwapParam.sol";

abstract contract SwapCalculatorGivenBalanceLimit is UniswapImmutableState {
  using Math for uint256;
  using UniswapV3PoolLibrary for address;

  function calculateSwapGivenBalanceLimit(
    UniswapV3CalculateSwapGivenBalanceLimitParam memory param
  ) internal returns (bool removeStrikeLimit, uint256 token0Amount, uint256 token1Amount) {
    uint256 maxTokenAmountNotSwapped = StrikeConversion
      .turn(param.tokenAmount, param.strike, !param.isToken0, false)
      .min(param.isToken0 ? param.token0Balance : param.token1Balance);

    uint256 tokenAmountIn;
    uint256 tokenAmountNotSwapped;
    if ((param.isToken0 ? param.token1Balance : param.token0Balance) != 0) {
      address pool = UniswapV3FactoryLibrary.getWithCheck(
        uniswapV3Factory,
        param.token0,
        param.token1,
        param.uniswapV3Fee
      );

      {
        uint256 amount = StrikeConversion.turn(param.tokenAmount, param.strike, param.isToken0, false).min(
          param.isToken0 ? param.token1Balance : param.token0Balance
        );

        bytes memory data = abi.encode(param.token0, param.token1, param.uniswapV3Fee);
        data = abi.encode(false, data);

        (tokenAmountIn, ) = pool.calculateSwap(
          UniswapV3CalculateSwapParam({
            zeroForOne: !param.isToken0,
            exactInput: true,
            amount: amount,
            strikeLimit: param.strike,
            data: data
          })
        );
      }

      tokenAmountNotSwapped = StrikeConversion.dif(
        param.tokenAmount,
        tokenAmountIn,
        param.strike,
        !param.isToken0,
        false
      );

      if (tokenAmountNotSwapped > maxTokenAmountNotSwapped) {
        removeStrikeLimit = true;

        tokenAmountNotSwapped = maxTokenAmountNotSwapped;

        tokenAmountIn = StrikeConversion.dif(
          param.tokenAmount,
          tokenAmountNotSwapped,
          param.strike,
          param.isToken0,
          false
        );
      }
    } else tokenAmountNotSwapped = maxTokenAmountNotSwapped;

    token0Amount = param.isToken0 ? tokenAmountNotSwapped : tokenAmountIn;
    token1Amount = param.isToken0 ? tokenAmountIn : tokenAmountNotSwapped;
  }
}

abstract contract SwapGetTotalToken is UniswapImmutableState {
  using UniswapV3PoolLibrary for address;

  function swapGetTotalToken(
    address token0,
    address token1,
    uint256 strike,
    uint24 uniswapV3Fee,
    address to,
    bool isToken0,
    uint256 token0Amount,
    uint256 token1Amount,
    bool removeStrikeLimit
  ) internal returns (uint256 tokenAmount) {
    tokenAmount = isToken0 ? token0Amount : token1Amount;

    if ((isToken0 ? token1Amount : token0Amount) != 0) {
      address pool = UniswapV3FactoryLibrary.getWithCheck(uniswapV3Factory, token0, token1, uniswapV3Fee);

      bytes memory data = abi.encode(token0, token1, uniswapV3Fee);
      data = abi.encode(true, data);

      (, uint256 tokenAmountOut) = pool.swap(
        UniswapV3SwapParam({
          recipient: to,
          zeroForOne: !isToken0,
          exactInput: true,
          amount: isToken0 ? token1Amount : token0Amount,
          strikeLimit: removeStrikeLimit ? 0 : strike,
          data: data
        })
      );

      tokenAmount += tokenAmountOut;
    }
  }
}