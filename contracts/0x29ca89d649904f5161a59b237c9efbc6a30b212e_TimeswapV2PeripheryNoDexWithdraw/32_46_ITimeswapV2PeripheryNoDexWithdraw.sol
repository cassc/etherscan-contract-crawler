// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

import {ITimeswapV2PeripheryWithdraw} from "@timeswap-labs/v2-periphery/contracts/interfaces/ITimeswapV2PeripheryWithdraw.sol";

import {INativeWithdraws} from "./INativeWithdraws.sol";
import {IMulticall} from "./IMulticall.sol";

import {TimeswapV2PeripheryNoDexWithdrawParam} from "../structs/Param.sol";

/// @title An interface for TS-V2 Periphery NoDex Withdraw.
interface ITimeswapV2PeripheryNoDexWithdraw is ITimeswapV2PeripheryWithdraw, INativeWithdraws, IMulticall {
  event Withdraw(
    address indexed token0,
    address indexed token1,
    uint256 strike,
    uint256 indexed maturity,
    address to,
    uint256 token0Amount,
    uint256 token1Amount,
    uint256 positionAmount
  );

  error MinTokenReached(uint256 tokenAmount, uint256 minTokenAmount);

  /// @dev The withdraw function.
  /// @param param Withdraw param.
  /// @return token0Amount
  /// @return token1Amount
  function withdraw(
    TimeswapV2PeripheryNoDexWithdrawParam calldata param
  ) external returns (uint256 token0Amount, uint256 token1Amount);
}