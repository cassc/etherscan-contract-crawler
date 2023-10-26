// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Address} from '@openzeppelin/contracts/utils/Address.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {IUniswapV2Pair} from '../interfaces/external/IUniswapV2Pair.sol';
import {IUniV2Router} from '../interfaces/IUniV2Router.sol';
import {LibUniV2Router} from '../libraries/LibUniV2Router.sol';
import {LibStarVault} from '../libraries/LibStarVault.sol';
import {LibWarp} from '../libraries/LibWarp.sol';
import {IUniswapV2Pair} from '../interfaces/external/IUniswapV2Pair.sol';
import {IPermit2} from '../interfaces/external/IPermit2.sol';
import {IAllowanceTransfer} from '../interfaces/external/IAllowanceTransfer.sol';
import {PermitParams} from '../libraries/PermitParams.sol';

contract UniV2RouterFacet is IUniV2Router {
  using SafeERC20 for IERC20;
  using Address for address;

  function uniswapV2ExactInputSingle(
    ExactInputSingleParams memory params,
    PermitParams calldata permit
  ) external payable returns (uint256 amountOut) {
    if (block.timestamp > params.deadline) {
      revert DeadlineExpired();
    }

    LibUniV2Router.DiamondStorage storage s = LibUniV2Router.diamondStorage();

    bool isFromEth = params.tokenIn == address(0);
    bool isToEth = params.tokenOut == address(0);

    if (isFromEth) {
      params.tokenIn = address(s.weth);
    }

    if (isToEth) {
      params.tokenOut = address(s.weth);
    }

    address pair = LibUniV2Router.pairFor(s.uniswapV2Factory, params.tokenIn, params.tokenOut);

    (uint256 reserveIn, uint256 reserveOut, ) = IUniswapV2Pair(pair).getReserves();

    if (params.tokenIn > params.tokenOut) {
      (reserveIn, reserveOut) = (reserveOut, reserveIn);
    }

    unchecked {
      amountOut =
        ((params.amountIn * 997) * reserveOut) /
        ((reserveIn * 1000) + (params.amountIn * 997));
    }

    // Enforce minimum amount/max slippage
    if (amountOut < LibWarp.applySlippage(params.amountOut, params.slippage)) {
      revert InsufficientOutputAmount();
    }

    if (isFromEth) {
      // From ETH
      if (msg.value != params.amountIn) {
        revert IncorrectEthValue();
      }

      s.weth.deposit{value: msg.value}();

      // Transfer tokens to the pool
      IERC20(params.tokenIn).safeTransfer(pair, params.amountIn);
    } else {
      // Permit tokens / set allowance
      s.permit2.permit(
        msg.sender,
        IAllowanceTransfer.PermitSingle({
          details: IAllowanceTransfer.PermitDetails({
            token: params.tokenIn,
            amount: (uint160)(params.amountIn),
            expiration: (uint48)(params.deadline),
            nonce: (uint48)(permit.nonce)
          }),
          spender: address(this),
          sigDeadline: (uint256)(params.deadline)
        }),
        permit.signature
      );

      // Transfer tokens from msg.sender to the pool
      s.permit2.transferFrom(msg.sender, pair, (uint160)(params.amountIn), params.tokenIn);
    }

    bool zeroForOne = params.tokenIn < params.tokenOut ? true : false;

    IUniswapV2Pair(pair).swap(
      zeroForOne ? 0 : amountOut,
      zeroForOne ? amountOut : 0,
      address(this),
      ''
    );

    // NOTE: Fee is collected as WETH instead of ETH
    amountOut = LibStarVault.calculateAndRegisterFee(
      params.partner,
      params.tokenOut,
      params.feeBps,
      params.amountOut,
      amountOut
    );

    if (amountOut == 0) {
      revert ZeroAmountOut();
    }

    if (isToEth) {
      // Unwrap WETH
      s.weth.withdraw(amountOut);

      (bool sent, ) = params.recipient.call{value: amountOut}('');

      if (!sent) {
        revert EthTransferFailed();
      }
    } else {
      IERC20(params.tokenOut).safeTransfer(params.recipient, amountOut);
    }

    emit LibWarp.Warp(
      params.partner,
      // NOTE: The tokens may have been rewritten to WETH
      isFromEth ? address(0) : params.tokenIn,
      isToEth ? address(0) : params.tokenOut,
      params.amountIn,
      amountOut
    );
  }

  function uniswapV2ExactInput(
    ExactInputParams memory params,
    PermitParams calldata permit
  ) external payable returns (uint256 amountOut) {
    if (block.timestamp > params.deadline) {
      revert DeadlineExpired();
    }

    LibUniV2Router.DiamondStorage storage s = LibUniV2Router.diamondStorage();

    uint256 pathLengthMinusOne = params.path.length - 1;
    bool isFromEth = params.path[0] == address(0);
    bool isToEth = params.path[pathLengthMinusOne] == address(0);

    if (isFromEth) {
      params.path[0] = address(s.weth);
    }

    if (isToEth) {
      params.path[pathLengthMinusOne] = address(s.weth);
    }

    (address[] memory pairs, uint256[] memory amounts) = LibUniV2Router.getPairsAndAmountsFromPath(
      s.uniswapV2Factory,
      params.amountIn,
      params.path
    );

    // Enforce minimum amount/max slippage
    if (amounts[amounts.length - 1] < LibWarp.applySlippage(params.amountOut, params.slippage)) {
      revert InsufficientOutputAmount();
    }

    if (isFromEth) {
      // From ETH
      if (msg.value != params.amountIn) {
        revert IncorrectEthValue();
      }

      s.weth.deposit{value: msg.value}();

      // Transfer tokens to the first pool
      IERC20(params.path[0]).safeTransfer(pairs[0], params.amountIn);
    } else {
      // Permit tokens / set allowance
      s.permit2.permit(
        msg.sender,
        IAllowanceTransfer.PermitSingle({
          details: IAllowanceTransfer.PermitDetails({
            token: params.path[0],
            amount: (uint160)(params.amountIn),
            expiration: (uint48)(params.deadline),
            nonce: (uint48)(permit.nonce)
          }),
          spender: address(this),
          sigDeadline: (uint256)(params.deadline)
        }),
        permit.signature
      );

      // Transfer tokens from msg.sender to the first pool
      s.permit2.transferFrom(msg.sender, pairs[0], (uint160)(params.amountIn), params.path[0]);
    }

    // https://github.com/Uniswap/v2-periphery/blob/master/contracts/UniswapV2Router02.sol
    for (uint index; index < pathLengthMinusOne; ) {
      uint256 indexPlusOne = index + 1;
      bool zeroForOne = params.path[index] < params.path[indexPlusOne] ? true : false;
      address to = index < params.path.length - 2 ? pairs[indexPlusOne] : address(this);

      IUniswapV2Pair(pairs[index]).swap(
        zeroForOne ? 0 : amounts[indexPlusOne],
        zeroForOne ? amounts[indexPlusOne] : 0,
        to,
        ''
      );

      unchecked {
        ++index;
      }
    }

    // NOTE: Fee is collected as WETH instead of ETH
    amountOut = LibStarVault.calculateAndRegisterFee(
      params.partner,
      params.path[pathLengthMinusOne],
      params.feeBps,
      params.amountOut,
      amounts[pathLengthMinusOne]
    );

    if (amountOut == 0) {
      revert ZeroAmountOut();
    }

    if (isToEth) {
      // Unwrap WETH
      s.weth.withdraw(amountOut);

      (bool sent, ) = params.recipient.call{value: amountOut}('');

      if (!sent) {
        revert EthTransferFailed();
      }
    } else {
      IERC20(params.path[pathLengthMinusOne]).safeTransfer(params.recipient, amountOut);
    }

    emit LibWarp.Warp(
      params.partner,
      // NOTE: The tokens may have been rewritten to WETH
      isFromEth ? address(0) : params.path[0],
      isToEth ? address(0) : params.path[pathLengthMinusOne],
      params.amountIn,
      amountOut
    );
  }
}