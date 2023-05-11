// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Math} from "@timeswap-labs/v2-library/contracts/Math.sol";

import {Error} from "@timeswap-labs/v2-library/contracts/Error.sol";
import {StrikeConversion} from "@timeswap-labs/v2-library/contracts/StrikeConversion.sol";

import {TimeswapV2OptionPosition} from "@timeswap-labs/v2-option/contracts/enums/Position.sol";

import {ITimeswapV2Token} from "@timeswap-labs/v2-token/contracts/interfaces/ITimeswapV2Token.sol";

import {TimeswapV2TokenPosition} from "@timeswap-labs/v2-token/contracts/structs/Position.sol";

import {TimeswapV2PeripheryCloseBorrowGivenPosition} from "@timeswap-labs/v2-periphery/contracts/TimeswapV2PeripheryCloseBorrowGivenPosition.sol";

import {TimeswapV2PeripheryCloseBorrowGivenPositionParam} from "@timeswap-labs/v2-periphery/contracts/structs/Param.sol";
import {TimeswapV2PeripheryCloseBorrowGivenPositionChoiceInternalParam, TimeswapV2PeripheryCloseBorrowGivenPositionInternalParam} from "@timeswap-labs/v2-periphery/contracts/structs/InternalParam.sol";

import {UniswapV3FactoryLibrary} from "./libraries/UniswapV3Factory.sol";
import {UniswapV3PoolLibrary} from "./libraries/UniswapV3Pool.sol";

import {ITimeswapV2PeripheryUniswapV3CloseBorrowGivenPosition} from "./interfaces/ITimeswapV2PeripheryUniswapV3CloseBorrowGivenPosition.sol";

import {TimeswapV2PeripheryUniswapV3CloseBorrowGivenPositionParam} from "./structs/Param.sol";
import {UniswapV3SwapParam, UniswapV3CalculateSwapParam} from "./structs/SwapParam.sol";

import {OnlyOperatorReceiver} from "./base/OnlyOperatorReceiver.sol";
import {NativeImmutableState, NativeWithdraws, NativePayments} from "./base/Native.sol";
import {UniswapImmutableState, UniswapV3CallbackWithOptionalNative} from "./base/UniswapV3SwapCallback.sol";
import {Multicall} from "./base/Multicall.sol";

/// @title Capable of closing a borrow position given a Timeswap V2 Position
/// @author Timeswap Labs
contract TimeswapV2PeripheryUniswapV3CloseBorrowGivenPosition is
  ITimeswapV2PeripheryUniswapV3CloseBorrowGivenPosition,
  TimeswapV2PeripheryCloseBorrowGivenPosition,
  OnlyOperatorReceiver,
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
    TimeswapV2PeripheryCloseBorrowGivenPosition(chosenOptionFactory, chosenPoolFactory, chosenTokens)
    NativeImmutableState(chosenNative)
    UniswapImmutableState(chosenUniswapV3Factory)
  {}

  /// @inheritdoc ITimeswapV2PeripheryUniswapV3CloseBorrowGivenPosition
  function closeBorrowGivenPosition(
    TimeswapV2PeripheryUniswapV3CloseBorrowGivenPositionParam calldata param
  ) external payable returns (uint256 tokenAmount) {
    if (param.deadline < block.timestamp) Error.deadlineReached(param.deadline);

    ITimeswapV2Token(tokens).transferTokenPositionFrom(
      msg.sender,
      address(this),
      TimeswapV2TokenPosition({
        token0: param.token0,
        token1: param.token1,
        strike: param.strike,
        maturity: param.maturity,
        position: param.isLong0 ? TimeswapV2OptionPosition.Long0 : TimeswapV2OptionPosition.Long1
      }),
      param.positionAmount
    );

    bytes memory data = abi.encode(msg.sender, param.uniswapV3Fee, param.to, param.isToken0);

    (, , data) = closeBorrowGivenPosition(
      TimeswapV2PeripheryCloseBorrowGivenPositionParam({
        token0: param.token0,
        token1: param.token1,
        strike: param.strike,
        maturity: param.maturity,
        to: (param.isToken0 == param.isLong0) ? address(this) : param.to,
        isLong0: param.isLong0,
        positionAmount: param.positionAmount,
        data: data
      })
    );

    tokenAmount = abi.decode(data, (uint256));

    if (tokenAmount > param.maxTokenAmount) revert MaxTokenReached(tokenAmount, param.maxTokenAmount);

    emit CloseBorrowGivenPosition(
      param.token0,
      param.token1,
      param.strike,
      param.maturity,
      param.uniswapV3Fee,
      msg.sender,
      param.to,
      param.isToken0,
      param.isLong0,
      tokenAmount,
      param.positionAmount
    );
  }

  function timeswapV2PeripheryCloseBorrowGivenPositionChoiceInternal(
    TimeswapV2PeripheryCloseBorrowGivenPositionChoiceInternalParam memory param
  ) internal override returns (uint256 token0Amount, uint256 token1Amount, bytes memory data) {
    (, uint24 uniswapV3Fee, , bool isToken0) = abi.decode(param.data, (address, uint24, address, bool));

    address pool = UniswapV3FactoryLibrary.getWithCheck(uniswapV3Factory, param.token0, param.token1, uniswapV3Fee);

    uint256 tokenAmountOut;

    data = abi.encode(param.token0, param.token1, uniswapV3Fee);
    data = abi.encode(false, data);

    (, tokenAmountOut) = pool.calculateSwap(
      UniswapV3CalculateSwapParam({
        zeroForOne: isToken0,
        exactInput: false,
        amount: StrikeConversion.turn(param.tokenAmount, param.strike, isToken0, true),
        strikeLimit: param.strike,
        data: data
      })
    );

    uint256 tokenAmountNotSwapped = StrikeConversion.dif(
      param.tokenAmount,
      tokenAmountOut,
      param.strike,
      !isToken0,
      true
    );

    token0Amount = isToken0 ? tokenAmountNotSwapped : tokenAmountOut;
    token1Amount = isToken0 ? tokenAmountOut : tokenAmountNotSwapped;

    data = param.data;
  }

  function timeswapV2PeripheryCloseBorrowGivenPositionInternal(
    TimeswapV2PeripheryCloseBorrowGivenPositionInternalParam memory param
  ) internal override returns (bytes memory data) {
    (address msgSender, uint24 uniswapV3Fee, address to, bool isToken0) = abi.decode(
      param.data,
      (address, uint24, address, bool)
    );

    uint256 tokenAmount = isToken0 ? param.token0Amount : param.token1Amount;
    if (isToken0 == param.isLong0) tokenAmount = param.positionAmount - tokenAmount;

    if ((isToken0 ? param.token1Amount : param.token0Amount) != 0) {
      address pool = UniswapV3FactoryLibrary.get(uniswapV3Factory, param.token0, param.token1, uniswapV3Fee);

      data = abi.encode(
        isToken0 == param.isLong0 ? address(this) : msgSender,
        param.token0,
        param.token1,
        uniswapV3Fee
      );
      data = abi.encode(true, data);

      uint256 tokenAmountOut = isToken0 ? param.token1Amount : param.token0Amount;
      if (isToken0 != param.isLong0) tokenAmountOut = param.positionAmount - tokenAmountOut;

      (uint256 tokenAmountIn, ) = pool.swap(
        UniswapV3SwapParam({
          recipient: isToken0 == param.isLong0 ? param.optionPair : to,
          zeroForOne: isToken0,
          exactInput: false,
          amount: tokenAmountOut,
          strikeLimit: param.strike,
          data: data
        })
      );

      tokenAmount += tokenAmountIn;
    }

    if (isToken0 == param.isLong0) {
      if (param.positionAmount > tokenAmount)
        IERC20(isToken0 ? param.token0 : param.token1).safeTransfer(to, param.positionAmount.unsafeSub(tokenAmount));
      else revert();
    } else
      pay(
        isToken0 ? param.token0 : param.token1,
        msgSender,
        param.optionPair,
        isToken0 ? param.token0Amount : param.token1Amount
      );

    data = abi.encode(tokenAmount);
  }
}