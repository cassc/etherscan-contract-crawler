// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

import {ITimeswapV2PeripheryCloseLendGivenPosition} from "@timeswap-labs/v2-periphery/contracts/interfaces/ITimeswapV2PeripheryCloseLendGivenPosition.sol";

import {INativeWithdraws} from "./INativeWithdraws.sol";
import {IMulticall} from "./IMulticall.sol";

import {TimeswapV2PeripheryNoDexCloseLendGivenPositionParam} from "../structs/Param.sol";

/// @title An interface for TS-V2 Periphery NoDex Close Lend Given Position.
interface ITimeswapV2PeripheryNoDexCloseLendGivenPosition is
  ITimeswapV2PeripheryCloseLendGivenPosition,
  INativeWithdraws,
  IMulticall
{
  event CloseLendGivenPosition(
    address indexed token0,
    address indexed token1,
    uint256 strike,
    uint256 indexed maturity,
    address from,
    address to,
    uint256 token0Amount,
    uint256 token1Amount,
    uint256 positionAmount
  );

  error MinTokenReached(uint256 tokenAmount, uint256 minTokenAmount);

  /// @dev The close lend given position function.
  /// @param param Close lend given position param.
  /// @return token0Amount
  /// @return token1Amount
  function closeLendGivenPosition(
    TimeswapV2PeripheryNoDexCloseLendGivenPositionParam calldata param
  ) external returns (uint256 token0Amount, uint256 token1Amount);
}