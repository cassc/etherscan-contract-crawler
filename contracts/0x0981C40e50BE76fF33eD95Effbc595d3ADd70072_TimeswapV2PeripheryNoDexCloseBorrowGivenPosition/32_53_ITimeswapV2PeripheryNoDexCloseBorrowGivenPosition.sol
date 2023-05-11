// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

import {ITimeswapV2PeripheryCloseBorrowGivenPosition} from "@timeswap-labs/v2-periphery/contracts/interfaces/ITimeswapV2PeripheryCloseBorrowGivenPosition.sol";

import {INativeWithdraws} from "./INativeWithdraws.sol";
import {INativePayments} from "./INativePayments.sol";
import {IMulticall} from "./IMulticall.sol";

import {TimeswapV2PeripheryNoDexCloseBorrowGivenPositionParam} from "../structs/Param.sol";

/// @title An interface for TS-v2 Periphery UniswapV3 Close Borrow Given Position.
interface ITimeswapV2PeripheryNoDexCloseBorrowGivenPosition is
  ITimeswapV2PeripheryCloseBorrowGivenPosition,
  INativeWithdraws,
  INativePayments,
  IMulticall
{
  event CloseBorrowGivenPosition(
    address indexed token0,
    address indexed token1,
    uint256 strike,
    uint256 indexed maturity,
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
    TimeswapV2PeripheryNoDexCloseBorrowGivenPositionParam calldata param
  ) external payable returns (uint256 tokenAmount);
}