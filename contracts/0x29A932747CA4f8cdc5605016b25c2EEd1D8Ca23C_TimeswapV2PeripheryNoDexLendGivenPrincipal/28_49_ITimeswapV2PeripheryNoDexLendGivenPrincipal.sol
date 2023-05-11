// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

import {ITimeswapV2PeripheryLendGivenPrincipal} from "@timeswap-labs/v2-periphery/contracts/interfaces/ITimeswapV2PeripheryLendGivenPrincipal.sol";

import {TimeswapV2PeripheryNoDexLendGivenPrincipalParam} from "../structs/Param.sol";

import {INativePayments} from "./INativePayments.sol";
import {IMulticall} from "./IMulticall.sol";

/// @title An interface for TS-V2 Periphery NoDex Lend Given Principal.
interface ITimeswapV2PeripheryNoDexLendGivenPrincipal is
  ITimeswapV2PeripheryLendGivenPrincipal,
  INativePayments,
  IMulticall
{
  event LendGivenPrincipal(
    address indexed token0,
    address indexed token1,
    uint256 strike,
    uint256 indexed maturity,
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
    TimeswapV2PeripheryNoDexLendGivenPrincipalParam calldata param
  ) external payable returns (uint256 positionAmount);
}