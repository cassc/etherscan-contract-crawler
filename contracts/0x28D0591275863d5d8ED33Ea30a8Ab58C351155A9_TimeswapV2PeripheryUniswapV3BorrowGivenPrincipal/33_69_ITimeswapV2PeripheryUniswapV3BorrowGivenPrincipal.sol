// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {IUniswapV3SwapCallback} from "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";

import {ITimeswapV2PeripheryBorrowGivenPrincipal} from "@timeswap-labs/v2-periphery/contracts/interfaces/ITimeswapV2PeripheryBorrowGivenPrincipal.sol";

import {TimeswapV2PeripheryUniswapV3BorrowGivenPrincipalParam} from "../structs/Param.sol";

import {INativeWithdraws} from "./INativeWithdraws.sol";
import {INativePayments} from "./INativePayments.sol";
import {IMulticall} from "./IMulticall.sol";

import {IUniswapImmutableState} from "./IUniswapImmutableState.sol";

/// @title An interface for TS-V2 Periphery UniswapV3 Borrow Given Pricipal.
interface ITimeswapV2PeripheryUniswapV3BorrowGivenPrincipal is
  ITimeswapV2PeripheryBorrowGivenPrincipal,
  IUniswapImmutableState,
  IUniswapV3SwapCallback,
  INativeWithdraws,
  INativePayments,
  IMulticall
{
  event BorrowGivenPrincipal(
    address indexed token0,
    address indexed token1,
    uint256 strike,
    uint256 indexed maturity,
    uint24 uniswapV3Fee,
    address from,
    address tokenTo,
    address longTo,
    bool isToken0,
    bool isLong0,
    uint256 tokenAmount,
    uint256 positionAmount
  );

  error MaxPositionReached(uint256 positionAmount, uint256 maxPositionAmount);

  /// @dev The borrow given principal function.
  /// @param param Borrow given principal param.
  /// @return positionAmount
  function borrowGivenPrincipal(
    TimeswapV2PeripheryUniswapV3BorrowGivenPrincipalParam calldata param
  ) external payable returns (uint256 positionAmount);
}