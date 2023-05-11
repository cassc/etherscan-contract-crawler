// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {IUniswapV3SwapCallback} from "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";

import {ITimeswapV2PeripheryCloseBorrowGivenPosition} from "@timeswap-labs/v2-periphery/contracts/interfaces/ITimeswapV2PeripheryCloseBorrowGivenPosition.sol";

import {TimeswapV2PeripheryUniswapV3CloseBorrowGivenPositionParam} from "../structs/Param.sol";

import {INativeWithdraws} from "./INativeWithdraws.sol";
import {INativePayments} from "./INativePayments.sol";
import {IMulticall} from "./IMulticall.sol";

import {IUniswapImmutableState} from "./IUniswapImmutableState.sol";

/// @title An interface for TS-v2 Periphery UniswapV3 Close Borrow Given Position.
interface ITimeswapV2PeripheryUniswapV3CloseBorrowGivenPosition is
  ITimeswapV2PeripheryCloseBorrowGivenPosition,
  IUniswapImmutableState,
  IUniswapV3SwapCallback,
  INativeWithdraws,
  INativePayments,
  IMulticall
{
  event CloseBorrowGivenPosition(
    address indexed token0,
    address indexed token1,
    uint256 strike,
    uint256 indexed maturity,
    uint24 uniswapV3Fee,
    address from,
    address to,
    bool isToken0,
    bool isLong0,
    uint256 tokenAmount,
    uint256 positionAmount
  );

  error MaxTokenReached(uint256 tokenAmount, uint256 maxTokenAmount);

  /// @dev The close borrow given position function.
  /// @param param Close borrow given position param.
  /// @return tokenAmount
  function closeBorrowGivenPosition(
    TimeswapV2PeripheryUniswapV3CloseBorrowGivenPositionParam calldata param
  ) external payable returns (uint256 tokenAmount);
}