// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../interfaces/ClipperLike.sol";
import "../interfaces/GemJoinLike.sol";
import "../interfaces/HayJoinLike.sol";
import "../interfaces/DogLike.sol";
import "../interfaces/VatLike.sol";
import "../ceros/interfaces/IHelioProvider.sol";
import "../oracle/libraries/FullMath.sol";

import { CollateralType } from  "../ceros/interfaces/IDao.sol";

uint256 constant RAY = 10**27;

library AuctionProxy {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using SafeERC20Upgradeable for GemLike;

  function startAuction(
    address user,
    address keeper,
    IERC20Upgradeable hay,
    HayJoinLike hayJoin,
    VatLike vat,
    DogLike dog,
    IHelioProvider helioProvider,
    CollateralType calldata collateral
  ) public returns (uint256 id) {
    ClipperLike _clip = ClipperLike(collateral.clip);
    _clip.upchost();
    uint256 hayBal = hay.balanceOf(address(this));
    id = dog.bark(collateral.ilk, user, address(this));

    hayJoin.exit(address(this), vat.hay(address(this)) / RAY);
    hayBal = hay.balanceOf(address(this)) - hayBal;
    hay.transfer(keeper, hayBal);

    // Burn any derivative token (hBNB incase of ceabnbc collateral)
    if (address(helioProvider) != address(0)) {
      helioProvider.daoBurn(user, _clip.sales(id).lot);
    }
  }

  function resetAuction(
    uint auctionId,
    address keeper,
    IERC20Upgradeable hay,
    HayJoinLike hayJoin,
    VatLike vat,
    CollateralType calldata collateral
  ) public {
    ClipperLike _clip = ClipperLike(collateral.clip);
    uint256 hayBal = hay.balanceOf(address(this));
    _clip.redo(auctionId, keeper);


    hayJoin.exit(address(this), vat.hay(address(this)) / RAY);
    hayBal = hay.balanceOf(address(this)) - hayBal;
    hay.transfer(keeper, hayBal);
  }

  // Returns lefover from auction
  function buyFromAuction(
    uint256 auctionId,
    uint256 collateralAmount,
    uint256 maxPrice,
    address receiverAddress,
    IERC20Upgradeable hay,
    HayJoinLike hayJoin,
    VatLike vat,
    IHelioProvider helioProvider,
    CollateralType calldata collateral
  ) public returns (uint256 leftover) {
    // Balances before
    uint256 hayBal = hay.balanceOf(address(this));
    uint256 gemBal = collateral.gem.gem().balanceOf(address(this));

    uint256 hayMaxAmount = FullMath.mulDiv(maxPrice, collateralAmount, RAY) + 1;

    hay.transferFrom(msg.sender, address(this), hayMaxAmount);
    hayJoin.join(address(this), hayMaxAmount);

    vat.hope(address(collateral.clip));
    address urn = ClipperLike(collateral.clip).sales(auctionId).usr; // Liquidated address

    leftover = vat.gem(collateral.ilk, urn); // userGemBalanceBefore
    ClipperLike(collateral.clip).take(auctionId, collateralAmount, maxPrice, address(this), "");
    leftover = vat.gem(collateral.ilk, urn) - leftover; // leftover

    collateral.gem.exit(address(this), vat.gem(collateral.ilk, address(this)));
    hayJoin.exit(address(this), vat.hay(address(this)) / RAY);

    // Balances rest
    hayBal = hay.balanceOf(address(this)) - hayBal;
    gemBal = collateral.gem.gem().balanceOf(address(this)) - gemBal;
    hay.transfer(receiverAddress, hayBal);

    vat.nope(address(collateral.clip));

    if (address(helioProvider) != address(0)) {
      IERC20Upgradeable(collateral.gem.gem()).safeTransfer(address(helioProvider), gemBal);
      helioProvider.liquidation(receiverAddress, gemBal); // Burn router ceToken and mint abnbc to receiver

      if (leftover != 0) {
        // Auction ended with leftover
        vat.flux(collateral.ilk, urn, address(this), leftover);
        collateral.gem.exit(address(helioProvider), leftover); // Router (disc) gets the remaining ceabnbc
        helioProvider.liquidation(urn, leftover); // Router burns them and gives abnbc remaining
      }
    } else {
      IERC20Upgradeable(collateral.gem.gem()).safeTransfer(receiverAddress, gemBal);
    }
  }

  function getAllActiveAuctionsForClip(ClipperLike clip)
    external
    view
    returns (Sale[] memory sales)
  {
    uint256[] memory auctionIds = clip.list();
    uint256 auctionsCount = auctionIds.length;
    sales = new Sale[](auctionsCount);
    for (uint256 i = 0; i < auctionsCount; i++) {
      sales[i] = clip.sales(auctionIds[i]);
    }
  }
}