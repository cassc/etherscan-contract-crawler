// (c) Copyright 2022, Bad Pumpkin Inc. All Rights Reserved
//
// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.6;

import { ICronV1PoolEnums } from "./ICronV1PoolEnums.sol";

interface ICronV1PoolEvents is ICronV1PoolEnums {
  /// @notice ShortTermSwap event is emitted for Short-Term (ST) swap transactions and
  ///         arbitrage partner ST swap transactions. To differentiate, examine the value of
  ///         swapType in the emitted event.
  ///
  event ShortTermSwap(
    address indexed sender,
    address indexed tokenIn,
    uint256 amountIn,
    uint256 amountOut,
    uint256 swapType
  );

  /// @notice LongTermSwap event is emitted when Long-Term (LT) swaps transaction are issued to
  ///         the pool.
  ///
  event LongTermSwap(
    address indexed sender,
    address indexed delegate,
    address indexed tokenIn,
    uint256 amountIn,
    uint256 intervals,
    uint256 orderId
  );

  /// @notice PoolJoin events are emitted for Join/Mint and Reward transactions. A Reward
  ///         transaction can be identified from a Join/Mint transaction by examining the
  ///         emitted event's poolTokenAmt to see if is zero.
  ///
  event PoolJoin(
    address indexed sender,
    address indexed recipient,
    uint256 token0In,
    uint256 token1In,
    uint256 poolTokenAmt
  );

  /// @notice WithdrawLongTermSwap events are emitted when an LT swap order is withdrawn or cancelled
  ///         in a transaction. To differentiate between the two, only a cancellation will have non-zero
  ///         values for refundOut.
  ///
  event WithdrawLongTermSwap(
    address indexed owner,
    address indexed refundToken,
    uint256 refundOut,
    address indexed proceedsToken,
    uint256 proceedsOut,
    uint256 orderId,
    address sender
  );

  /// @notice FeeWithdraw events are emitted when Cron-Fi fees are withdrawn from the pool.
  ///
  event FeeWithdraw(address indexed sender, uint256 token0Out, uint256 token1Out);

  /// @notice PoolExit events are emitted when a Liquidity Provider (LP) redeems LP tokens for
  ///         their share of tokens remaining in the pool.
  ///
  event PoolExit(address indexed sender, uint256 poolTokenAmt, uint256 token0Out, uint256 token1Out);

  /// @notice AdministratorStatusChange events are emitted when an administrator address, admin,
  ///         is given administrator privileges (status == true) or when they are taken away
  ///         (status == false).
  ///
  event AdministratorStatusChange(address indexed sender, address indexed admin, bool status);

  /// @notice ProtocolFeeTooLarge is emitted if the protocol fee passed in by balancer ever exceeds
  ///         1e18 (in which case the change is ignored and fees continue with the last good value).
  ///
  event ProtocolFeeTooLarge(uint256 suggestedProtocolFee);

  /// @notice ParameterChange is emitted when a parameter value is changed to value. Consult the
  ///         enum ParmType for the parameter undergoing change.
  ///
  event ParameterChange(address indexed sender, ParamType paramType, uint256 value);

  /// @notice FeeAddressChange is emitted when the fee address, feeAddress, is changed.
  ///
  event FeeAddressChange(address indexed sender, address indexed feeAddress);

  /// @notice FeeShiftChange is emitted when the fee shift, feeShift is changed.
  ///
  event FeeShiftChange(address indexed sender, uint256 feeShift);

  /// @notice BoolParameterChange is emitted when a boolean value parameter is changed. Consult the
  ///         enum BoolParmType for the parameter undergoing change.
  ///
  event BoolParameterChange(address indexed sender, BoolParamType boolParam, bool value);

  /// @notice UpdatedArbitragePartner is emitted when an arbitrage partner's arbitrageur list is
  ///         updated to a new contract address.
  ///
  event UpdatedArbitragePartner(address indexed sender, address partner, address list);

  /// @notice UpdatedArbitrageList is emitted when an arbitrage partner's updates their arbitrageur
  ///         list is to a new contract address through the updateArbitrageList function.
  ///
  event UpdatedArbitrageList(address indexed partner, address indexed oldList, address indexed newList);

  /// @notice ExecuteVirtualOrdersEvent is emitted on calls to executeVirtualOrdersToBlock.
  ///
  event ExecuteVirtualOrdersEvent(address indexed sender, uint256 block);
}