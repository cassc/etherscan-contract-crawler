// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Error} from "@timeswap-labs/v2-library/contracts/Error.sol";
import {Math} from "@timeswap-labs/v2-library/contracts/Math.sol";

import {StrikeConversion} from "@timeswap-labs/v2-library/contracts/StrikeConversion.sol";

import {TimeswapV2OptionPosition} from "@timeswap-labs/v2-option/contracts/enums/Position.sol";

import {ITimeswapV2Token} from "@timeswap-labs/v2-token/contracts/interfaces/ITimeswapV2Token.sol";

import {TimeswapV2TokenPosition} from "@timeswap-labs/v2-token/contracts/structs/Position.sol";

import {TimeswapV2PeripheryCloseLendGivenPosition} from "@timeswap-labs/v2-periphery/contracts/TimeswapV2PeripheryCloseLendGivenPosition.sol";

import {TimeswapV2PeripheryCloseLendGivenPositionParam} from "@timeswap-labs/v2-periphery/contracts/structs/Param.sol";
import {TimeswapV2PeripheryCloseLendGivenPositionChoiceInternalParam} from "@timeswap-labs/v2-periphery/contracts/structs/InternalParam.sol";

import {ITimeswapV2PeripheryNoDexCloseLendGivenPosition} from "./interfaces/ITimeswapV2PeripheryNoDexCloseLendGivenPosition.sol";

import {OnlyOperatorReceiver} from "./base/OnlyOperatorReceiver.sol";
import {NativeImmutableState, NativeWithdraws, NativePayments} from "./base/Native.sol";
import {Multicall} from "./base/Multicall.sol";

import {TimeswapV2PeripheryNoDexCloseLendGivenPositionParam} from "./structs/Param.sol";

/// @title Capable of closing a lend position given a Timeswap V2 Position
/// @author Timeswap Labs
contract TimeswapV2PeripheryNoDexCloseLendGivenPosition is
  ITimeswapV2PeripheryNoDexCloseLendGivenPosition,
  TimeswapV2PeripheryCloseLendGivenPosition,
  OnlyOperatorReceiver,
  NativeImmutableState,
  NativeWithdraws,
  NativePayments,
  Multicall
{
  using Math for uint256;
  using SafeERC20 for IERC20;

  constructor(
    address chosenOptionFactory,
    address chosenPoolFactory,
    address chosenTokens,
    address chosenNative
  )
    TimeswapV2PeripheryCloseLendGivenPosition(chosenOptionFactory, chosenPoolFactory, chosenTokens)
    NativeImmutableState(chosenNative)
  {}

  /// @inheritdoc ITimeswapV2PeripheryNoDexCloseLendGivenPosition
  function closeLendGivenPosition(
    TimeswapV2PeripheryNoDexCloseLendGivenPositionParam memory param
  ) external returns (uint256 token0Amount, uint256 token1Amount) {
    if (param.deadline < block.timestamp) Error.deadlineReached(param.deadline);

    ITimeswapV2Token(tokens).transferTokenPositionFrom(
      msg.sender,
      address(this),
      TimeswapV2TokenPosition({
        token0: param.token0,
        token1: param.token1,
        strike: param.strike,
        maturity: param.maturity,
        position: TimeswapV2OptionPosition.Short
      }),
      param.positionAmount
    );

    bytes memory data = abi.encode(param.isToken0);

    (token0Amount, token1Amount, data) = closeLendGivenPosition(
      TimeswapV2PeripheryCloseLendGivenPositionParam({
        token0: param.token0,
        token1: param.token1,
        strike: param.strike,
        maturity: param.maturity,
        token0To: param.to,
        token1To: param.to,
        positionAmount: param.positionAmount,
        data: data
      })
    );

    if (token0Amount < param.minToken0Amount) revert MinTokenReached(token0Amount, param.minToken0Amount);
    if (token1Amount < param.minToken1Amount) revert MinTokenReached(token1Amount, param.minToken1Amount);

    emit CloseLendGivenPosition(
      param.token0,
      param.token1,
      param.strike,
      param.maturity,
      msg.sender,
      param.to,
      token0Amount,
      token1Amount,
      param.positionAmount
    );
  }

  function timeswapV2PeripheryCloseLendGivenPositionChoiceInternal(
    TimeswapV2PeripheryCloseLendGivenPositionChoiceInternalParam memory param
  ) internal pure override returns (uint256 token0Amount, uint256 token1Amount, bytes memory data) {
    bool isToken0 = abi.decode(param.data, (bool));
    uint256 maxPrefferedTokenAmount = StrikeConversion.turn(param.tokenAmount, param.strike, !isToken0, false);
    uint256 prefferedTokenAmount = isToken0 ? param.token0Balance : param.token1Balance;
    uint256 otherTokenAmount;
    if (maxPrefferedTokenAmount <= prefferedTokenAmount) prefferedTokenAmount = maxPrefferedTokenAmount;
    else
      otherTokenAmount = StrikeConversion.dif(param.tokenAmount, prefferedTokenAmount, param.strike, isToken0, false);

    token0Amount = isToken0 ? prefferedTokenAmount : otherTokenAmount;
    token1Amount = isToken0 ? otherTokenAmount : prefferedTokenAmount;

    data = bytes("");
  }
}