// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {IUniswapV3SwapCallback} from "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";

import {ITimeswapV2PeripheryLendGivenPrincipal} from "@timeswap-labs/v2-periphery/contracts/interfaces/ITimeswapV2PeripheryLendGivenPrincipal.sol";

import {TimeswapV2PeripheryUniswapV3LendGivenPrincipalParam} from "../structs/Param.sol";

import {INativePayments} from "./INativePayments.sol";
import {IMulticall} from "./IMulticall.sol";

import {IUniswapImmutableState} from "./IUniswapImmutableState.sol";

/// @title An interface for TS-V2 Periphery UniswapV3 Lend Given Principal.
interface ITimeswapV2PeripheryUniswapV3LendGivenPrincipal is
  ITimeswapV2PeripheryLendGivenPrincipal,
  IUniswapImmutableState,
  IUniswapV3SwapCallback,
  INativePayments,
  IMulticall
{
  event LendGivenPrincipal(
    address indexed token0,
    address indexed token1,
    uint256 strike,
    uint256 indexed maturity,
    uint24 uniswapV3Fee,
    address from,
    address to,
    bool isToken0,
    uint256 tokenAmount,
    uint256 positionAmount
  );

  error MinPositionReached(uint256 positionAmount, uint256 minReturnAmount);

  /// @dev The lend given principal function.
  /// @param param Lend given principal param.
  /// @return positionAmount
  function lendGivenPrincipal(
    TimeswapV2PeripheryUniswapV3LendGivenPrincipalParam calldata param
  ) external payable returns (uint256 positionAmount);
}