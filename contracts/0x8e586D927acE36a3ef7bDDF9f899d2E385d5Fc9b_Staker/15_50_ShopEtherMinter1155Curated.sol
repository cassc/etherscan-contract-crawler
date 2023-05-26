// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./FeeOwner.sol";
import "./Fee1155.sol";

/**
  @title A simple Shop contract for selling ERC-1155s for Ether via direct
         minting.
  @author Tim Clancy

  This contract is a limited subset of the Shop1155 contract designed to mint
  items directly to the user upon purchase. This shop additionally requires the
  owner to directly approve purchase requests from prospective buyers.
*/
contract ShopEtherMinter1155Curated is ERC1155Holder, Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /// A version number for this Shop contract's interface.
  uint256 public version = 1;

  /// @dev A mask for isolating an item's group ID.
  uint256 constant GROUP_MASK = uint256(uint128(~0)) << 128;

  /// A user-specified Fee1155 contract to support selling items from.
  Fee1155 public item;

  /// A user-specified FeeOwner to receive a portion of Shop earnings.
  FeeOwner public feeOwner;

  /// The Shop's inventory of item groups for sale.
  uint256[] public inventory;

  /// The Shop's price for each item group.
  mapping (uint256 => uint256) public prices;

  /// A mapping of each item group ID to an array of addresses with offers.
  mapping (uint256 => address[]) public bidders;

  /// A mapping for each item group ID to a mapping of address-price offers.
  mapping (uint256 => mapping (address => uint256)) public offers;

  /**
    Construct a new Shop by providing it a FeeOwner.

    @param _item The address of the Fee1155 item that will be minting sales.
    @param _feeOwner The address of the FeeOwner due a portion of Shop earnings.
  */
  constructor(Fee1155 _item, FeeOwner _feeOwner) public {
    item = _item;
    feeOwner = _feeOwner;
  }

  /**
    Returns the length of the inventory array.

    @return the length of the inventory array.
  */
  function getInventoryCount() external view returns (uint256) {
    return inventory.length;
  }

  /**
    Returns the length of the bidder array on an item group.

    @return the length of the bidder array on an item group.
  */
  function getBidderCount(uint256 groupId) external view returns (uint256) {
    return bidders[groupId].length;
  }

  /**
    Allows the Shop owner to list a new set of NFT items for sale.

    @param _groupIds The item group IDs to list for sale in this shop.
    @param _prices The corresponding purchase price to mint an item of each group.
  */
  function listItems(uint256[] calldata _groupIds, uint256[] calldata _prices) external onlyOwner {
    require(_groupIds.length > 0,
      "You must list at least one item.");
    require(_groupIds.length == _prices.length,
      "Items length cannot be mismatched with prices length.");

    // Iterate through every specified item group to list items.
    for (uint256 i = 0; i < _groupIds.length; i++) {
      uint256 groupId = _groupIds[i];
      uint256 price = _prices[i];
      inventory.push(groupId);
      prices[groupId] = price;
    }
  }

  /**
    Allows the Shop owner to remove items from sale.

    @param _groupIds The group IDs currently listed in the shop to take off sale.
  */
  function removeItems(uint256[] calldata _groupIds) external onlyOwner {
    require(_groupIds.length > 0,
      "You must remove at least one item.");

    // Iterate through every specified item group to remove items.
    for (uint256 i = 0; i < _groupIds.length; i++) {
      uint256 groupId = _groupIds[i];
      prices[groupId] = 0;
    }
  }

  /**
    Allows any user to place an offer to purchase an item group from this Shop.
    For this shop, users place an offer automatically at the price set by the
    Shop owner. This function takes a user's Ether into escrow for the offer.

    @param _itemGroupIds An array of (unique) item groups for a user to place an offer for.
  */
  function makeOffers(uint256[] calldata _itemGroupIds) public nonReentrant payable {
    require(_itemGroupIds.length > 0,
      "You must make an offer for at least one item group.");

    // Iterate through every specified item to make an offer on items.
    for (uint256 i = 0; i < _itemGroupIds.length; i++) {
      uint256 groupId = _itemGroupIds[i];
      uint256 price = prices[groupId];
      require(price > 0,
        "You cannot make an offer for an item that is not listed.");

      // Record an offer for this item.
      bidders[groupId].push(msg.sender);
      offers[groupId][msg.sender] = msg.value;
    }
  }

  /**
    Allows any user to cancel an offer for items from this Shop. This function
    returns a user's Ether if there is any in escrow for the item group.

    @param _itemGroupIds An array of (unique) item groups for a user to cancel an offer for.
  */
  function cancelOffers(uint256[] calldata _itemGroupIds) public nonReentrant {
    require(_itemGroupIds.length > 0,
      "You must cancel an offer for at least one item group.");

    // Iterate through every specified item to cancel offers on items.
    uint256 returnedOfferAmount = 0;
    for (uint256 i = 0; i < _itemGroupIds.length; i++) {
      uint256 groupId = _itemGroupIds[i];
      uint256 offeredValue = offers[groupId][msg.sender];
      returnedOfferAmount = returnedOfferAmount.add(offeredValue);
      offers[groupId][msg.sender] = 0;
    }

    // Return the user's escrowed offer Ether.
    (bool success, ) = payable(msg.sender).call{ value: returnedOfferAmount }("");
    require(success, "Returning canceled offer amount failed.");
  }

  /**
    Allows the Shop owner to accept any valid offer from a user. Once the Shop
    owner accepts the offer, the Ether is distributed according to fees and the
    item is minted to the user.

    @param _groupIds The item group IDs to process offers for.
    @param _bidders The specific bidder for each item group ID to accept.
    @param _itemIds The specific item ID within the group to mint for the bidder.
    @param _amounts The amount of specific item to mint for the bidder.
  */
  function acceptOffers(uint256[] calldata _groupIds, address[] calldata _bidders, uint256[] calldata _itemIds, uint256[] calldata _amounts) public nonReentrant onlyOwner {
    require(_groupIds.length > 0,
      "You must accept an offer for at least one item.");
    require(_groupIds.length == _bidders.length,
      "Group IDs length cannot be mismatched with bidders length.");
    require(_groupIds.length == _itemIds.length,
      "Group IDs length cannot be mismatched with item IDs length.");
    require(_groupIds.length == _amounts.length,
      "Group IDs length cannot be mismatched with item amounts length.");

    // Accept all offers and disperse fees accordingly.
    uint256 feePercent = feeOwner.fee();
    uint256 itemRoyaltyPercent = item.feeOwner().fee();
    for (uint256 i = 0; i < _groupIds.length; i++) {
      uint256 groupId = _groupIds[i];
      address bidder = _bidders[i];
      uint256 itemId = _itemIds[i];
      uint256 amount = _amounts[i];

      // Verify that the offer being accepted is still valid.
      uint256 price = prices[groupId];
      require(price > 0,
        "You cannot accept an offer for an item that is not listed.");
      uint256 offeredPrice = offers[groupId][bidder];
      require(offeredPrice >= price,
        "You cannot accept an offer for less than the current asking price.");

      // Split fees for this purchase.
      uint256 feeValue = offeredPrice.mul(feePercent).div(100000);
      uint256 royaltyValue = offeredPrice.mul(itemRoyaltyPercent).div(100000);
      (bool success, ) = payable(feeOwner.owner()).call{ value: feeValue }("");
      require(success, "Platform fee transfer failed.");
      (success, ) = payable(item.feeOwner().owner()).call{ value: royaltyValue }("");
      require(success, "Creator royalty transfer failed.");
      (success, ) = payable(owner()).call{ value: offeredPrice.sub(feeValue).sub(royaltyValue) }("");
      require(success, "Shop owner transfer failed.");

      // Mint the item.
      item.mint(bidder, itemId, amount, "");
    }
  }
}