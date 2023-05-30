// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {IERC20} from '../../../dependencies/openzeppelin/contracts/IERC20.sol';
import {IBalancerVault} from '../../../interfaces/IBalancerVault.sol';
import {SafeERC20} from '../../../dependencies/openzeppelin/contracts/SafeERC20.sol';
import {Errors} from '../../libraries/helpers/Errors.sol';

library BalancerswapAdapter2 {
  using SafeERC20 for IERC20;

  struct Path {
    address[] tokens;
    bytes32[] poolIds;
  }

  address constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

  function swapExactTokensForTokens(
    address assetToSwapFrom,
    address assetToSwapTo,
    uint256 amountToSwap,
    Path calldata path,
    uint256 minAmountOut
  ) external returns (uint256) {
    // Check path is valid
    uint256 length = path.tokens.length;
    require(length > 1 && length - 1 == path.poolIds.length, Errors.VT_SWAP_PATH_LENGTH_INVALID);
    require(
      path.tokens[0] == assetToSwapFrom && path.tokens[length - 1] == assetToSwapTo,
      Errors.VT_SWAP_PATH_TOKEN_INVALID
    );

    // Approves the transfer for the swap. Approves for 0 first to comply with tokens that implement the anti frontrunning approval fix.
    IERC20(assetToSwapFrom).safeApprove(address(BALANCER_VAULT), 0);
    if (IERC20(assetToSwapFrom).allowance(address(this), address(BALANCER_VAULT)) == 0)
      IERC20(assetToSwapFrom).safeApprove(address(BALANCER_VAULT), amountToSwap);

    IBalancerVault.BatchSwapStep[] memory swaps = new IBalancerVault.BatchSwapStep[](length - 1);
    int256[] memory limits = new int256[](length);
    for (uint256 i; i < length - 1; ++i) {
      swaps[i] = IBalancerVault.BatchSwapStep({
        poolId: path.poolIds[i],
        assetInIndex: i,
        assetOutIndex: i + 1,
        amount: 0,
        userData: '0'
      });
    }
    swaps[0].amount = amountToSwap;
    limits[0] = int256(amountToSwap);
    unchecked {
      limits[length - 1] = int256(0 - minAmountOut);
    }

    IBalancerVault.FundManagement memory funds = IBalancerVault.FundManagement({
      sender: address(this),
      fromInternalBalance: false,
      recipient: payable(address(this)),
      toInternalBalance: false
    });

    int256[] memory receivedAmount = IBalancerVault(BALANCER_VAULT).batchSwap(
      IBalancerVault.SwapKind.GIVEN_IN,
      swaps,
      path.tokens,
      funds,
      limits,
      block.timestamp
    );

    uint256 receivedPositveAmount;
    unchecked {
      receivedPositveAmount = uint256(0 - receivedAmount[length - 1]);
    }

    require(receivedPositveAmount != 0, Errors.VT_SWAP_MISMATCH_RETURNED_AMOUNT);
    require(
      IERC20(assetToSwapTo).balanceOf(address(this)) >= receivedPositveAmount,
      Errors.VT_SWAP_MISMATCH_RETURNED_AMOUNT
    );

    return receivedPositveAmount;
  }
}