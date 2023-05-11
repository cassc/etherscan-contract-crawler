// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Error} from "@timeswap-labs/v2-library/contracts/Error.sol";
import {Math} from "@timeswap-labs/v2-library/contracts/Math.sol";

import {TimeswapV2PeripheryLendGivenPrincipal} from "@timeswap-labs/v2-periphery/contracts/TimeswapV2PeripheryLendGivenPrincipal.sol";

import {TimeswapV2PeripheryLendGivenPrincipalParam} from "@timeswap-labs/v2-periphery/contracts/structs/Param.sol";
import {TimeswapV2PeripheryLendGivenPrincipalInternalParam} from "@timeswap-labs/v2-periphery/contracts/structs/InternalParam.sol";

import {ITimeswapV2PeripheryNoDexLendGivenPrincipal} from "./interfaces/ITimeswapV2PeripheryNoDexLendGivenPrincipal.sol";

import {TimeswapV2PeripheryNoDexLendGivenPrincipalParam} from "./structs/Param.sol";

import {NativeImmutableState, NativePayments} from "./base/Native.sol";
import {Multicall} from "./base/Multicall.sol";

/// @title Capable of lending in the Timeswap V2 Protocol given a principal amount
/// @author Timeswap Labs
contract TimeswapV2PeripheryNoDexLendGivenPrincipal is
  ITimeswapV2PeripheryNoDexLendGivenPrincipal,
  TimeswapV2PeripheryLendGivenPrincipal,
  NativeImmutableState,
  Multicall,
  NativePayments
{
  using Math for uint256;
  using SafeERC20 for IERC20;

  constructor(
    address chosenOptionFactory,
    address chosenPoolFactory,
    address chosenTokens,
    address chosenNative
  )
    TimeswapV2PeripheryLendGivenPrincipal(chosenOptionFactory, chosenPoolFactory, chosenTokens)
    NativeImmutableState(chosenNative)
  {}

  /// @inheritdoc ITimeswapV2PeripheryNoDexLendGivenPrincipal
  function lendGivenPrincipal(
    TimeswapV2PeripheryNoDexLendGivenPrincipalParam calldata param
  ) external payable override returns (uint256 positionAmount) {
    if (param.deadline < block.timestamp) Error.deadlineReached(param.deadline);

    bytes memory data = abi.encode(msg.sender, param.isToken0);

    (positionAmount, ) = lendGivenPrincipal(
      TimeswapV2PeripheryLendGivenPrincipalParam({
        token0: param.token0,
        token1: param.token1,
        strike: param.strike,
        maturity: param.maturity,
        to: param.to,
        token0Amount: param.isToken0 ? param.tokenAmount : 0,
        token1Amount: param.isToken0 ? 0 : param.tokenAmount,
        data: data
      })
    );

    if (positionAmount < param.minReturnAmount) revert MinPositionReached(positionAmount, param.minReturnAmount);

    emit LendGivenPrincipal(
      param.token0,
      param.token1,
      param.strike,
      param.maturity,
      msg.sender,
      param.to,
      param.isToken0,
      param.tokenAmount,
      positionAmount
    );
  }

  function timeswapV2PeripheryLendGivenPrincipalInternal(
    TimeswapV2PeripheryLendGivenPrincipalInternalParam memory param
  ) internal override returns (bytes memory data) {
    (address msgSender, bool isToken0) = abi.decode(param.data, (address, bool));

    if ((isToken0 ? param.token0Amount : param.token1Amount) != 0)
      pay(
        isToken0 ? param.token0 : param.token1,
        msgSender,
        param.optionPair,
        isToken0 ? param.token0Amount : param.token1Amount
      );

    data = bytes("");
  }
}