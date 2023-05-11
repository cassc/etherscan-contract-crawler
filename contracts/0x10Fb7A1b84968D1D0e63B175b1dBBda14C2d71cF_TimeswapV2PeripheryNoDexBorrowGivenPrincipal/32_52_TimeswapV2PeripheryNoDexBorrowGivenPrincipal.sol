// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Error} from "@timeswap-labs/v2-library/contracts/Error.sol";

import {StrikeConversion} from "@timeswap-labs/v2-library/contracts/StrikeConversion.sol";

import {TimeswapV2OptionPosition} from "@timeswap-labs/v2-option/contracts/enums/Position.sol";

import {ITimeswapV2Pool} from "@timeswap-labs/v2-pool/contracts/interfaces/ITimeswapV2Pool.sol";

import {PoolFactoryLibrary} from "@timeswap-labs/v2-pool/contracts/libraries/PoolFactory.sol";

import {ITimeswapV2Token} from "@timeswap-labs/v2-token/contracts/interfaces/ITimeswapV2Token.sol";

import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3SwapCallback} from "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";

import {TimeswapV2PeripheryBorrowGivenPrincipal} from "@timeswap-labs/v2-periphery/contracts/TimeswapV2PeripheryBorrowGivenPrincipal.sol";

import {TimeswapV2PeripheryBorrowGivenPrincipalParam} from "@timeswap-labs/v2-periphery/contracts/structs/Param.sol";
import {TimeswapV2PeripheryBorrowGivenPrincipalInternalParam} from "@timeswap-labs/v2-periphery/contracts/structs/InternalParam.sol";

import {ITimeswapV2PeripheryNoDexBorrowGivenPrincipal} from "./interfaces/ITimeswapV2PeripheryNoDexBorrowGivenPrincipal.sol";

import {TimeswapV2PeripheryNoDexBorrowGivenPrincipalParam} from "./structs/Param.sol";

import {Error} from "@timeswap-labs/v2-library/contracts/Error.sol";
import {NativeImmutableState, NativeWithdraws, NativePayments} from "./base/Native.sol";
import {Multicall} from "./base/Multicall.sol";
import {Math} from "@timeswap-labs/v2-library/contracts/Math.sol";

/// @title Capable of borrowing a given amount of principal from a Timeswap V2 pool
/// @author Timeswap Labs
contract TimeswapV2PeripheryNoDexBorrowGivenPrincipal is
  ITimeswapV2PeripheryNoDexBorrowGivenPrincipal,
  TimeswapV2PeripheryBorrowGivenPrincipal,
  NativeImmutableState,
  NativePayments,
  NativeWithdraws,
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
    TimeswapV2PeripheryBorrowGivenPrincipal(chosenOptionFactory, chosenPoolFactory, chosenTokens)
    NativeImmutableState(chosenNative)
  {}

  /// @inheritdoc ITimeswapV2PeripheryNoDexBorrowGivenPrincipal
  function borrowGivenPrincipal(
    TimeswapV2PeripheryNoDexBorrowGivenPrincipalParam calldata param
  ) external payable override returns (uint256 positionAmount) {
    if (param.deadline < block.timestamp) Error.deadlineReached(param.deadline);

    (, address poolPair) = PoolFactoryLibrary.getWithCheck(optionFactory, poolFactory, param.token0, param.token1);

    (uint256 token0Balance, uint256 token1Balance) = ITimeswapV2Pool(poolPair).totalLongBalanceAdjustFees(
      param.strike,
      param.maturity
    );

    if (param.isToken0) Error.checkEnough(token0Balance, param.tokenAmount);
    else Error.checkEnough(token1Balance, param.tokenAmount);
    bytes memory data = abi.encode(msg.sender, param.tokenTo, param.isToken0);

    (positionAmount, ) = borrowGivenPrincipal(
      TimeswapV2PeripheryBorrowGivenPrincipalParam({
        token0: param.token0,
        token1: param.token1,
        strike: param.strike,
        maturity: param.maturity,
        tokenTo: param.isToken0 == param.isLong0 ? address(this) : param.tokenTo,
        longTo: param.longTo,
        isLong0: param.isLong0,
        token0Amount: param.isToken0 ? param.tokenAmount : 0,
        token1Amount: param.isToken0 ? 0 : param.tokenAmount,
        data: data
      })
    );

    if (positionAmount > param.maxPositionAmount) revert MaxPositionReached(positionAmount, param.maxPositionAmount);

    emit BorrowGivenPrincipal(
      param.token0,
      param.token1,
      param.strike,
      param.maturity,
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
    (address msgSender, , ) = abi.decode(param.data, (address, address, bool));

    pay(
      param.isLong0 ? param.token0 : param.token1,
      msgSender,
      param.optionPair,
      param.isLong0 ? param.token0Amount : param.token1Amount
    );

    data = bytes("");
  }
}