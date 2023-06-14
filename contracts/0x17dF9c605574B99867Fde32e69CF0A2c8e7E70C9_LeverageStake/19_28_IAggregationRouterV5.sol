// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IAggregationRouterV5 {
  function clipperSwap(
    address clipperExchange,
    address srcToken,
    address dstToken,
    uint256 inputAmount,
    uint256 outputAmount,
    uint256 goodUntil,
    bytes32 r,
    bytes32 vs
  ) external payable returns (uint256 returnAmount);

  function clipperSwapTo(
    address clipperExchange,
    address recipient,
    address srcToken,
    address dstToken,
    uint256 inputAmount,
    uint256 outputAmount,
    uint256 goodUntil,
    bytes32 r,
    bytes32 vs
  ) external payable returns (uint256 returnAmount);

  function clipperSwapToWithPermit(
    address clipperExchange,
    address recipient,
    address srcToken,
    address dstToken,
    uint256 inputAmount,
    uint256 outputAmount,
    uint256 goodUntil,
    bytes32 r,
    bytes32 vs,
    bytes memory permit
  ) external returns (uint256 returnAmount);

  function fillOrder(
    OrderLib.Order memory order,
    bytes memory signature,
    bytes memory interaction,
    uint256 makingAmount,
    uint256 takingAmount,
    uint256 skipPermitAndThresholdAmount
  ) external payable returns (uint256, uint256, bytes32);

  function fillOrderRFQ(
    OrderRFQLib.OrderRFQ memory order,
    bytes memory signature,
    uint256 flagsAndAmount
  ) external payable returns (uint256, uint256, bytes32);

  function fillOrderRFQCompact(
    OrderRFQLib.OrderRFQ memory order,
    bytes32 r,
    bytes32 vs,
    uint256 flagsAndAmount
  )
    external
    payable
    returns (uint256 filledMakingAmount, uint256 filledTakingAmount, bytes32 orderHash);

  function fillOrderRFQTo(
    OrderRFQLib.OrderRFQ memory order,
    bytes memory signature,
    uint256 flagsAndAmount,
    address target
  )
    external
    payable
    returns (uint256 filledMakingAmount, uint256 filledTakingAmount, bytes32 orderHash);

  function fillOrderRFQToWithPermit(
    OrderRFQLib.OrderRFQ memory order,
    bytes memory signature,
    uint256 flagsAndAmount,
    address target,
    bytes memory permit
  ) external returns (uint256, uint256, bytes32);

  function fillOrderTo(
    OrderLib.Order memory order_,
    bytes memory signature,
    bytes memory interaction,
    uint256 makingAmount,
    uint256 takingAmount,
    uint256 skipPermitAndThresholdAmount,
    address target
  )
    external
    payable
    returns (uint256 actualMakingAmount, uint256 actualTakingAmount, bytes32 orderHash);

  function fillOrderToWithPermit(
    OrderLib.Order memory order,
    bytes memory signature,
    bytes memory interaction,
    uint256 makingAmount,
    uint256 takingAmount,
    uint256 skipPermitAndThresholdAmount,
    address target,
    bytes memory permit
  ) external returns (uint256, uint256, bytes32);

  function swap(
    address executor,
    GenericRouter.SwapDescription memory desc,
    bytes memory permit,
    bytes memory data
  ) external payable returns (uint256 returnAmount, uint256 spentAmount);

  function uniswapV3Swap(
    uint256 amount,
    uint256 minReturn,
    uint256[] memory pools
  ) external payable returns (uint256 returnAmount);

  function uniswapV3SwapTo(
    address recipient,
    uint256 amount,
    uint256 minReturn,
    uint256[] memory pools
  ) external payable returns (uint256 returnAmount);

  function uniswapV3SwapToWithPermit(
    address recipient,
    address srcToken,
    uint256 amount,
    uint256 minReturn,
    uint256[] memory pools,
    bytes memory permit
  ) external returns (uint256 returnAmount);

  function unoswap(
    address srcToken,
    uint256 amount,
    uint256 minReturn,
    uint256[] memory pools
  ) external payable returns (uint256 returnAmount);

  function unoswapTo(
    address recipient,
    address srcToken,
    uint256 amount,
    uint256 minReturn,
    uint256[] memory pools
  ) external payable returns (uint256 returnAmount);

  function unoswapToWithPermit(
    address recipient,
    address srcToken,
    uint256 amount,
    uint256 minReturn,
    uint256[] memory pools,
    bytes memory permit
  ) external returns (uint256 returnAmount);
}

interface OrderLib {
  struct Order {
    uint256 salt;
    address makerAsset;
    address takerAsset;
    address maker;
    address receiver;
    address allowedSender;
    uint256 makingAmount;
    uint256 takingAmount;
    uint256 offsets;
    bytes interactions;
  }
}

interface OrderRFQLib {
  struct OrderRFQ {
    uint256 info;
    address makerAsset;
    address takerAsset;
    address maker;
    address allowedSender;
    uint256 makingAmount;
    uint256 takingAmount;
  }
}

interface GenericRouter {
  struct SwapDescription {
    address srcToken;
    address dstToken;
    address srcReceiver;
    address dstReceiver;
    uint256 amount;
    uint256 minReturnAmount;
    uint256 flags;
  }
}

interface IUniswapV2Router02 {
  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);
}

interface IUniswapV3Pool {
  function token0() external view returns (address);

  function token1() external view returns (address);
}