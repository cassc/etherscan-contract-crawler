// SPDX-License-Identifier: ISC
pragma solidity ^0.8.9;

import "../interfaces/IIndexToken.sol";
import "../interfaces/IIndexMinter.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "pancake-contracts/projects/exchange-protocol/contracts/interfaces/IPancakeRouter02.sol";
import "hardhat/console.sol";

contract ExchangeMinter {
  struct SwapExactIn {
    address[] path;
    uint256 amountIn;
    uint256 amountOutMin;
  }

  struct SwapExactOut {
    address[] path;
    uint256 amountInMax;
    uint256 amountOut;
  }

  function issueExactIndexForTokens(
    IIndexToken token,
    IIndexMinter minter,
    uint256 amountOut,
    IPancakeRouter02 router,
    SwapExactOut[] memory swaps
  ) external {
    console.log("buying");
    for (uint256 i = 0; i < swaps.length; i++) {
      SwapExactOut memory swap = swaps[i];
      SafeERC20.safeTransferFrom(IERC20(swap.path[0]), msg.sender, address(this), swap.amountInMax);
      if (swap.path.length > 1) {
        SafeERC20.safeApprove(IERC20(swap.path[0]), address(router), swap.amountInMax);
        router.swapTokensForExactTokens(
          swap.amountOut,
          swap.amountInMax,
          swap.path,
          address(this),
          block.timestamp
        );
        SafeERC20.safeApprove(IERC20(swap.path[0]), address(router), 0);
      }
    }

    IIndexToken.Asset[] memory assets = token.getAssets();
    for (uint256 i = 0; i < assets.length; i++) {
      IIndexToken.Asset memory asset = assets[i];
      uint256 amountIn = Math.mulDiv(asset.amount, amountOut, 10**18);
      SafeERC20.safeApprove(IERC20(asset.assetToken), address(minter), amountIn);      
    }

    minter.issue(token, amountOut);
    SafeERC20.safeTransfer(token, msg.sender, amountOut);
  }

  function redeemTokensForExactIndex(
    IIndexToken token,
    IIndexMinter minter,
    uint256 amountIn,
    IPancakeRouter02 router,
    SwapExactIn[] memory swaps
  ) external {
    SafeERC20.safeTransferFrom(token, msg.sender, address(this), amountIn);
    minter.redeem(token, amountIn);

    for (uint256 i = 0; i < swaps.length; i++) {
      SwapExactIn memory swap = swaps[i];
      if (swap.path.length > 1) {
        SafeERC20.safeApprove(IERC20(swap.path[0]), address(router), swap.amountIn);
        router.swapExactTokensForTokens(
          swap.amountIn,
          swap.amountOutMin,
          swap.path,
          msg.sender,
          block.timestamp
        );
        SafeERC20.safeApprove(IERC20(swap.path[0]), address(router), 0);
      } else {
        SafeERC20.safeTransfer(IERC20(swap.path[0]), msg.sender, swap.amountIn);
      }
    }
  }
}