// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;
pragma abicoder v2;

import {IERC20} from '../../../dependencies/openzeppelin/contracts/IERC20.sol';
import {ICurveAddressProvider} from '../../../interfaces/ICurveAddressProvider.sol';
import {ICurveExchange} from '../../../interfaces/ICurveExchange.sol';
import {ILendingPoolAddressesProvider} from '../../../interfaces/ILendingPoolAddressesProvider.sol';
import {SafeERC20} from '../../../dependencies/openzeppelin/contracts/SafeERC20.sol';
import {Errors} from '../../libraries/helpers/Errors.sol';

library CurveswapAdapter2 {
  using SafeERC20 for IERC20;

  struct Path {
    address[9] routes;
    uint256[3][4] swapParams;
  }

  address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  function swapExactTokensForTokens(
    ILendingPoolAddressesProvider addressesProvider,
    address assetToSwapFrom,
    address assetToSwapTo,
    uint256 amountToSwap,
    Path calldata path,
    uint256 minAmountOut
  ) external returns (uint256) {
    // Approves the transfer for the swap. Approves for 0 first to comply with tokens that implement the anti frontrunning approval fix.
    address curveAddressProvider = addressesProvider.getAddress('CURVE_ADDRESS_PROVIDER');
    address curveExchange = ICurveAddressProvider(curveAddressProvider).get_address(2);

    IERC20(assetToSwapFrom).safeApprove(address(curveExchange), 0);
    IERC20(assetToSwapFrom).safeApprove(address(curveExchange), amountToSwap);

    address[4] memory pools;
    uint256 receivedAmount = ICurveExchange(curveExchange).exchange_multiple(
      path.routes,
      path.swapParams,
      amountToSwap,
      minAmountOut,
      pools,
      address(this)
    );

    require(receivedAmount != 0, Errors.VT_SWAP_MISMATCH_RETURNED_AMOUNT);
    uint256 balanceOfAsset;
    if (assetToSwapTo == ETH) {
      balanceOfAsset = address(this).balance;
    } else {
      balanceOfAsset = IERC20(assetToSwapTo).balanceOf(address(this));
    }
    require(balanceOfAsset >= receivedAmount, Errors.VT_SWAP_MISMATCH_RETURNED_AMOUNT);
    return receivedAmount;
  }
}