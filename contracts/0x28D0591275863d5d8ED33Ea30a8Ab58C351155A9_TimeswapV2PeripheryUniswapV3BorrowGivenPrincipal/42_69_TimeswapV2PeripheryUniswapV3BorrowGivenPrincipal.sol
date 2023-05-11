// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Error} from "@timeswap-labs/v2-library/contracts/Error.sol";

import {ITimeswapV2Pool} from "@timeswap-labs/v2-pool/contracts/interfaces/ITimeswapV2Pool.sol";

import {PoolFactoryLibrary} from "@timeswap-labs/v2-pool/contracts/libraries/PoolFactory.sol";

import {TimeswapV2PeripheryBorrowGivenPrincipal} from "@timeswap-labs/v2-periphery/contracts/TimeswapV2PeripheryBorrowGivenPrincipal.sol";

import {TimeswapV2PeripheryBorrowGivenPrincipalParam} from "@timeswap-labs/v2-periphery/contracts/structs/Param.sol";
import {TimeswapV2PeripheryBorrowGivenPrincipalInternalParam} from "@timeswap-labs/v2-periphery/contracts/structs/InternalParam.sol";

import {UniswapV3FactoryLibrary} from "./libraries/UniswapV3Factory.sol";
import {UniswapV3PoolLibrary} from "./libraries/UniswapV3Pool.sol";

import {ITimeswapV2PeripheryUniswapV3BorrowGivenPrincipal} from "./interfaces/ITimeswapV2PeripheryUniswapV3BorrowGivenPrincipal.sol";

import {TimeswapV2PeripheryUniswapV3BorrowGivenPrincipalParam} from "./structs/Param.sol";
import {UniswapV3SwapParam, UniswapV3CalculateSwapParam} from "./structs/SwapParam.sol";

import {NativeImmutableState, NativeWithdraws, NativePayments} from "./base/Native.sol";
import {UniswapImmutableState, UniswapV3CallbackWithOptionalNative} from "./base/UniswapV3SwapCallback.sol";
import {Multicall} from "./base/Multicall.sol";
import {Math} from "@timeswap-labs/v2-library/contracts/Math.sol";

/// @title Capable of borrowing a given amount of principal from a Timeswap V2 pool
/// @author Timeswap Labs
contract TimeswapV2PeripheryUniswapV3BorrowGivenPrincipal is
  ITimeswapV2PeripheryUniswapV3BorrowGivenPrincipal,
  TimeswapV2PeripheryBorrowGivenPrincipal,
  NativeImmutableState,
  NativeWithdraws,
  UniswapV3CallbackWithOptionalNative,
  Multicall
{
  using UniswapV3PoolLibrary for address;
  using Math for uint256;
  using SafeERC20 for IERC20;

  constructor(
    address chosenOptionFactory,
    address chosenPoolFactory,
    address chosenTokens,
    address chosenUniswapV3Factory,
    address chosenNative
  )
    TimeswapV2PeripheryBorrowGivenPrincipal(chosenOptionFactory, chosenPoolFactory, chosenTokens)
    NativeImmutableState(chosenNative)
    UniswapImmutableState(chosenUniswapV3Factory)
  {}

  /// @inheritdoc ITimeswapV2PeripheryUniswapV3BorrowGivenPrincipal
  function borrowGivenPrincipal(
    TimeswapV2PeripheryUniswapV3BorrowGivenPrincipalParam calldata param
  ) external payable override returns (uint256 positionAmount) {
    if (param.deadline < block.timestamp) Error.deadlineReached(param.deadline);

    {
      (, address poolPair) = PoolFactoryLibrary.getWithCheck(optionFactory, poolFactory, param.token0, param.token1);

      (uint256 token0Balance, uint256 token1Balance) = ITimeswapV2Pool(poolPair).totalLongBalanceAdjustFees(
        param.strike,
        param.maturity
      );

      address pool = UniswapV3FactoryLibrary.getWithCheck(
        uniswapV3Factory,
        param.token0,
        param.token1,
        param.uniswapV3Fee
      );

      bool exactInput;
      bool removeStrikeLimit;
      uint256 tokenAmountIn;
      uint256 tokenAmountOut;
      bytes memory data = abi.encode(param.token0, param.token1, param.uniswapV3Fee);
      data = abi.encode(false, data);
      if ((param.isToken0 ? token1Balance : token0Balance) != 0) {
        (tokenAmountIn, tokenAmountOut) = pool.calculateSwap(
          UniswapV3CalculateSwapParam({
            zeroForOne: !param.isToken0,
            exactInput: false,
            amount: param.tokenAmount,
            strikeLimit: param.strike,
            data: data
          })
        );

        if (tokenAmountIn > (param.isToken0 ? token1Balance : token0Balance))
          (tokenAmountIn, tokenAmountOut) = pool.calculateSwap(
            UniswapV3CalculateSwapParam({
              zeroForOne: !param.isToken0,
              exactInput: (exactInput = true),
              amount: param.isToken0 ? token1Balance : token0Balance,
              strikeLimit: param.strike,
              data: data
            })
          );
      }

      if (param.tokenAmount - tokenAmountOut > (param.isToken0 ? token0Balance : token1Balance)) {
        removeStrikeLimit = true;

        UniswapV3CalculateSwapParam memory internalParam = UniswapV3CalculateSwapParam({
          zeroForOne: !param.isToken0,
          exactInput: (exactInput = false),
          amount: param.tokenAmount - (param.isToken0 ? token0Balance : token1Balance),
          strikeLimit: 0,
          data: data
        });

        (tokenAmountIn, tokenAmountOut) = pool.calculateSwap(internalParam);
      }

      data = abi.encode(
        msg.sender,
        param.uniswapV3Fee,
        param.tokenTo,
        param.isToken0,
        exactInput,
        removeStrikeLimit,
        tokenAmountOut
      );

      (positionAmount, ) = borrowGivenPrincipal(
        TimeswapV2PeripheryBorrowGivenPrincipalParam({
          token0: param.token0,
          token1: param.token1,
          strike: param.strike,
          maturity: param.maturity,
          tokenTo: param.isToken0 == param.isLong0 ? address(this) : param.tokenTo,
          longTo: param.longTo,
          isLong0: param.isLong0,
          token0Amount: param.isToken0 ? param.tokenAmount - tokenAmountOut : tokenAmountIn,
          token1Amount: param.isToken0 ? tokenAmountIn : param.tokenAmount - tokenAmountOut,
          data: data
        })
      );
    }

    if (positionAmount > param.maxPositionAmount) revert MaxPositionReached(positionAmount, param.maxPositionAmount);

    emit BorrowGivenPrincipal(
      param.token0,
      param.token1,
      param.strike,
      param.maturity,
      param.uniswapV3Fee,
      msg.sender,
      param.tokenTo,
      param.longTo,
      param.isToken0,
      param.isLong0,
      param.tokenAmount,
      positionAmount
    );
  }

  function timeswapV2PeripheryBorrowGivenPrincipalInternal(
    TimeswapV2PeripheryBorrowGivenPrincipalInternalParam memory param
  ) internal override returns (bytes memory data) {
    (
      address msgSender,
      uint24 uniswapV3Fee,
      address tokenTo,
      bool isToken0,
      bool exactInput,
      bool removeStrikeLimit,
      uint256 tokenAmountOut
    ) = abi.decode(param.data, (address, uint24, address, bool, bool, bool, uint256));

    if ((exactInput ? (isToken0 ? param.token1Amount : param.token0Amount) : tokenAmountOut) != 0) {
      address pool = UniswapV3FactoryLibrary.get(uniswapV3Factory, param.token0, param.token1, uniswapV3Fee);

      data = abi.encode(
        isToken0 == param.isLong0 ? address(this) : msgSender,
        param.token0,
        param.token1,
        uniswapV3Fee
      );
      data = abi.encode(true, data);

      (, tokenAmountOut) = pool.swap(
        UniswapV3SwapParam({
          recipient: isToken0 == param.isLong0 ? address(this) : tokenTo,
          zeroForOne: !isToken0,
          exactInput: exactInput,
          amount: exactInput ? (isToken0 ? param.token1Amount : param.token0Amount) : tokenAmountOut,
          strikeLimit: removeStrikeLimit ? 0 : param.strike,
          data: data
        })
      );

      data = bytes("");
    }

    if (isToken0 == param.isLong0) {
      if ((param.isLong0 ? param.token0Amount : param.token1Amount) > tokenAmountOut)
        pay(
          param.isLong0 ? param.token0 : param.token1,
          msgSender,
          address(this),
          (param.isLong0 ? param.token0Amount : param.token1Amount).unsafeSub(tokenAmountOut)
        );
      else if ((param.isLong0 ? param.token0Amount : param.token1Amount) < tokenAmountOut)
        IERC20(param.isLong0 ? param.token0 : param.token1).safeTransfer(
          tokenTo,
          tokenAmountOut.unsafeSub(param.isLong0 ? param.token0Amount : param.token1Amount)
        );

      IERC20(param.isLong0 ? param.token0 : param.token1).safeTransfer(
        param.optionPair,
        param.isLong0 ? param.token0Amount : param.token1Amount
      );
    } else
      pay(
        param.isLong0 ? param.token0 : param.token1,
        msgSender,
        param.optionPair,
        param.isLong0 ? param.token0Amount : param.token1Amount
      );
  }
}