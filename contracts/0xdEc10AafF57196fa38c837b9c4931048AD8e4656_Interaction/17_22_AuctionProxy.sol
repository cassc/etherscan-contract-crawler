// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../interfaces/ClipperLike.sol";
import "../interfaces/GemJoinLike.sol";
import "../interfaces/DavosJoinLike.sol";
import "../interfaces/DogLike.sol";
import "../interfaces/VatLike.sol";
import "../ceros/interfaces/IDavosProvider.sol";
import "../oracle/libraries/FullMath.sol";

import { CollateralType } from  "../ceros/interfaces/IInteraction.sol";

uint256 constant RAY = 10**27;

library AuctionProxy {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using SafeERC20Upgradeable for GemLike;

  function startAuction(
    address user,
    address keeper,
    IERC20Upgradeable davos,
    DavosJoinLike davosJoin,
    VatLike vat,
    DogLike dog,
    IDavosProvider davosProvider,
    CollateralType calldata collateral
  ) public returns (uint256 id) {
    ClipperLike _clip = ClipperLike(collateral.clip);
    _clip.upchost();
    uint256 davosBal = davos.balanceOf(address(this));
    id = dog.bark(collateral.ilk, user, address(this));

    davosJoin.exit(address(this), vat.davos(address(this)) / RAY);
    davosBal = davos.balanceOf(address(this)) - davosBal;
    davos.transfer(keeper, davosBal);

    // Burn any derivative token (dMATIC incase of ceaMATICc collateral)
    if (address(davosProvider) != address(0)) {
      davosProvider.daoBurn(user, _clip.sales(id).lot);
    }
  }

  function resetAuction(
    uint auctionId,
    address keeper,
    IERC20Upgradeable davos,
    DavosJoinLike davosJoin,
    VatLike vat,
    CollateralType calldata collateral
  ) public {
    ClipperLike _clip = ClipperLike(collateral.clip);
    uint256 davosBal = davos.balanceOf(address(this));
    _clip.redo(auctionId, keeper);


    davosJoin.exit(address(this), vat.davos(address(this)) / RAY);
    davosBal = davos.balanceOf(address(this)) - davosBal;
    davos.transfer(keeper, davosBal);
  }

  // Returns lefover from auction
  function buyFromAuction(
    uint256 auctionId,
    uint256 collateralAmount,
    uint256 maxPrice,
    address receiverAddress,
    IERC20Upgradeable davos,
    DavosJoinLike davosJoin,
    VatLike vat,
    IDavosProvider davosProvider,
    CollateralType calldata collateral
  ) public returns (uint256 leftover) {
    // Balances before
    uint256 davosBal = davos.balanceOf(address(this));
    uint256 gemBal = collateral.gem.gem().balanceOf(address(this));

    uint256 davosMaxAmount = FullMath.mulDiv(maxPrice, collateralAmount, RAY);

    davos.transferFrom(msg.sender, address(this), davosMaxAmount);
    davosJoin.join(address(this), davosMaxAmount);

    vat.hope(address(collateral.clip));
    address urn = ClipperLike(collateral.clip).sales(auctionId).usr; // Liquidated address

    leftover = vat.gem(collateral.ilk, urn); // userGemBalanceBefore
    ClipperLike(collateral.clip).take(auctionId, collateralAmount, maxPrice, address(this), "");
    leftover = vat.gem(collateral.ilk, urn) - leftover; // leftover

    collateral.gem.exit(address(this), vat.gem(collateral.ilk, address(this)));
    davosJoin.exit(address(this), vat.davos(address(this)) / RAY);

    // Balances rest
    davosBal = davos.balanceOf(address(this)) - davosBal;
    gemBal = collateral.gem.gem().balanceOf(address(this)) - gemBal;
    davos.transfer(receiverAddress, davosBal);

    vat.nope(address(collateral.clip));

    if (address(davosProvider) != address(0)) {
      IERC20Upgradeable(collateral.gem.gem()).safeTransfer(address(davosProvider), gemBal);
      davosProvider.liquidation(receiverAddress, gemBal); // Burn router ceToken and mint amaticc to receiver

      if (leftover != 0) {
        // Auction ended with leftover
        vat.flux(collateral.ilk, urn, address(this), leftover);
        collateral.gem.exit(address(davosProvider), leftover); // Router (disc) gets the remaining ceamaticc
        davosProvider.liquidation(urn, leftover); // Router burns them and gives amaticc remaining
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