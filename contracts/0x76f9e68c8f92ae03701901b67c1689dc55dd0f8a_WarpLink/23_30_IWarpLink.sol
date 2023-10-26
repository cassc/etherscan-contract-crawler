// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {PermitParams} from '../libraries/PermitParams.sol';
import {ILibCurve} from '../interfaces/ILibCurve.sol';
import {ILibStarVault} from '../interfaces/ILibStarVault.sol';
import {ILibUniV3Like} from '../interfaces/ILibUniV3Like.sol';
import {ILibWarp} from '../interfaces/ILibWarp.sol';

interface IWarpLink is ILibCurve, ILibStarVault, ILibUniV3Like, ILibWarp {
  error UnhandledCommand();
  error InsufficientEthValue();
  error InsufficientOutputAmount();
  error InsufficientTokensDelivered();
  error UnexpectedTokenForWrap();
  error UnexpectedTokenForUnwrap();
  error UnexpectedTokenOut();
  error InsufficientAmountRemaining();
  error NotEnoughParts();
  error InconsistentPartTokenOut();
  error InconsistentPartPayerOut();
  error UnexpectedPayerForWrap();
  error NativeTokenNotSupported();
  error DeadlineExpired();
  error IllegalJumpInSplit();
  error JumpMustBeLastCommand();
  error InvalidSgReceiverSender();
  error InvalidSgReceiveSrcAddress();

  struct Params {
    address partner;
    uint16 feeBps;
    /**
     * How much below `amountOut` the user will accept
     */
    uint16 slippageBps;
    address recipient;
    address tokenIn;
    address tokenOut;
    uint256 amountIn;
    /**
     * The amount the user was quoted
     */
    uint256 amountOut;
    uint48 deadline;
    bytes commands;
  }

  function warpLinkEngage(Params memory params, PermitParams calldata permit) external payable;
}