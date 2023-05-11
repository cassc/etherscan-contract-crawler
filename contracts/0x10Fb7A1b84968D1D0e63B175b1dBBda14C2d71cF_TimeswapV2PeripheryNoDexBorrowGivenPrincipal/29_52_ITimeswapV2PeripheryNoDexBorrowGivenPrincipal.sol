// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

import {ITimeswapV2PeripheryBorrowGivenPrincipal} from "@timeswap-labs/v2-periphery/contracts/interfaces/ITimeswapV2PeripheryBorrowGivenPrincipal.sol";

import {TimeswapV2PeripheryNoDexBorrowGivenPrincipalParam} from "../structs/Param.sol";

import {INativeWithdraws} from "./INativeWithdraws.sol";
import {INativePayments} from "./INativePayments.sol";
import {IMulticall} from "./IMulticall.sol";

/// @title An interface for TS-V2 Periphery NoDex Borrow Given Pricipal.
interface ITimeswapV2PeripheryNoDexBorrowGivenPrincipal is
  ITimeswapV2PeripheryBorrowGivenPrincipal,
  INativeWithdraws,
  INativePayments,
  IMulticall
{
  event BorrowGivenPrincipal(
    address indexed token0,
    address indexed token1,
    uint256 strike,
    uint256 indexed maturity,
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
    TimeswapV2PeripheryNoDexBorrowGivenPrincipalParam calldata param
  ) external payable returns (uint256 positionAmount);
}