// SPDX-License-Identifier: ISC
pragma solidity ^0.8.9;

import "../interfaces/IIndexToken.sol";
import "../interfaces/IIndexMinter.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "hardhat/console.sol";

contract IndexMinter is IIndexMinter {
  function issue(IIndexToken token, uint256 amount) external {
    console.log("issuing");
    IIndexToken.Asset[] memory assets = token.getAssets();

    for (uint256 i = 0; i < assets.length; i++) {
      console.log(IERC20Metadata(assets[i].assetToken).symbol());
      uint256 amountIn = Math.mulDiv(assets[i].amount, amount, 10 ** token.decimals());
      console.log(IERC20(assets[i].assetToken).balanceOf(msg.sender), amountIn);
      SafeERC20.safeTransferFrom(
        IERC20(assets[i].assetToken),
        msg.sender,
        address(token),
        amountIn
      );
    }

    token.mint(msg.sender, amount);
  }

  function redeem(IIndexToken token, uint256 amount) external returns (RedeemResult[] memory) {
    console.log("redeeming");
    IIndexToken.Asset[] memory assets = token.getAssets();
    RedeemResult[] memory result = new RedeemResult[](assets.length);

    // take fee on redeems
    address feeReceiver = token.getFeeReceiver();
    if (msg.sender != feeReceiver) {
      uint256 feeAmount = amount * 12 / 10000;
      SafeERC20.safeTransferFrom(
        token,
        msg.sender,
        token.getFeeReceiver(),
        feeAmount
      );
      amount -= feeAmount;
    }

    for (uint256 i = 0; i < assets.length; i++) {
      uint256 amountOut = Math.mulDiv(assets[i].amount, amount, 10 ** token.decimals());
      token.transferAsset(assets[i].assetToken, msg.sender, amountOut);
      result[i].token = assets[i].assetToken;
      result[i].amount = amountOut;
    }

    token.burn(msg.sender, amount);
    return result;
  }
}