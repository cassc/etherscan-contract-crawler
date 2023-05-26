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
import "./Staker.sol";

/**
  @title A simple Shop contract for selling ERC-1155s for points, Ether, or
         ERC-20 tokens.
  @author Tim Clancy

  This contract allows its owner to list NFT items for sale. NFT items are
  purchased by users using points spent on a corresponding Staker contract.
  The Shop must be approved by the owner of the Staker contract.
*/
contract Shop1155 is ERC1155Holder, Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /// A version number for this Shop contract's interface.
  uint256 public version = 1;

  /// A user-specified, descriptive name for this Shop.
  string public name;

  /// A user-specified FeeOwner to receive a portion of Shop earnings.
  FeeOwner public feeOwner;

  /// A user-specified Staker contract to spend user points on.
  Staker[] public stakers;

  /**
    This struct tracks information about a single asset with associated price
    that an item is being sold in the shop for.

    @param assetType A sentinel value for the specific type of asset being used.
                     0 = non-transferrable points from a Staker; see `asset`.
                     1 = Ether.
                     2 = an ERC-20 token, see `asset`.
    @param asset Some more specific information about the asset to charge in.
                 If the `assetType` is 0, we convert the given address to an
                 integer index for finding a specific Staker from `stakers`.
                 If the `assetType` is 1, we ignore this field.
                 If the `assetType` is 2, we use this address to find the ERC-20
                 token that we should be specifically charging with.
    @param price The amount of the specified `assetType` and `asset` to charge.
  */
  struct PricePair {
    uint256 assetType;
    address asset;
    uint256 price;
  }

  /**
    This struct tracks information about each item of inventory in the Shop.

    @param token The address of a Fee1155 collection contract containing the
                 item we want to sell.
    @param id The specific ID of the item within the Fee1155 from `token`.
    @param amount The amount of this specific item on sale in the Shop.
  */
  struct ShopItem {
    Fee1155 token;
    uint256 id;
    uint256 amount;
  }

  // The Shop's inventory of items for sale.
  uint256 nextItemId;
  mapping (uint256 => ShopItem) public inventory;
  mapping (uint256 => uint256) public pricePairLengths;
  mapping (uint256 => mapping (uint256 => PricePair)) public prices;

  /**
    Construct a new Shop by providing it a name, FeeOwner, optional Stakers. Any
    attached Staker contracts must also approve this Shop to spend points.

    @param _name The name of the Shop contract.
    @param _feeOwner The address of the FeeOwner due a portion of Shop earnings.
    @param _stakers The addresses of any Stakers to permit spending points from.
  */
  constructor(string memory _name, FeeOwner _feeOwner, Staker[] memory _stakers) public {
    name = _name;
    feeOwner = _feeOwner;
    stakers = _stakers;
    nextItemId = 0;
  }

  /**
    Returns the length of the Staker array.

    @return the length of the Staker array.
  */
  function getStakerCount() external view returns (uint256) {
    return stakers.length;
  }

  /**
    Returns the number of items in the Shop's inventory.

    @return the number of items in the Shop's inventory.
  */
  function getInventoryCount() external view returns (uint256) {
    return nextItemId;
  }

  /**
    Allows the Shop owner to add newly-supported Stakers for point spending.

    @param _stakers The array of new Stakers to add.
  */
  function addStakers(Staker[] memory _stakers) external onlyOwner {
    for (uint256 i = 0; i < _stakers.length; i++) {
      stakers.push(_stakers[i]);
    }
  }

  /**
    Allows the Shop owner to list a new set of NFT items for sale.

    @param _pricePairs The asset address to price pairings to use for selling
                       each item.
    @param _items The array of Fee1155 item contracts to sell from.
    @param _ids The specific Fee1155 item IDs to sell.
    @param _amounts The amount of inventory being listed for each item.
  */
  function listItems(PricePair[] memory _pricePairs, Fee1155[] calldata _items, uint256[][] calldata _ids, uint256[][] calldata _amounts) external nonReentrant onlyOwner {
    require(_items.length > 0,
      "You must list at least one item.");
    require(_items.length == _ids.length,
      "Items length cannot be mismatched with IDs length.");
    require(_items.length == _amounts.length,
      "Items length cannot be mismatched with amounts length.");

    // Iterate through every specified Fee1155 contract to list items.
    for (uint256 i = 0; i < _items.length; i++) {
      Fee1155 item = _items[i];
      uint256[] memory ids = _ids[i];
      uint256[] memory amounts = _amounts[i];
      require(ids.length > 0,
        "You must specify at least one item ID.");
      require(ids.length == amounts.length,
        "Item IDs length cannot be mismatched with amounts length.");

      // For each Fee1155 contract, add the requested item IDs to the Shop.
      for (uint256 j = 0; j < ids.length; j++) {
        uint256 id = ids[j];
        uint256 amount = amounts[j];
        require(amount > 0,
          "You cannot list an item with no starting amount.");
        inventory[nextItemId + j] = ShopItem({
          token: item,
          id: id,
          amount: amount
        });
        for (uint k = 0; k < _pricePairs.length; k++) {
          prices[nextItemId + j][k] = _pricePairs[k];
        }
        pricePairLengths[nextItemId + j] = _pricePairs.length;
      }
      nextItemId = nextItemId.add(ids.length);

      // Batch transfer the listed items to the Shop contract.
      item.safeBatchTransferFrom(msg.sender, address(this), ids, amounts, "");
    }
  }

  /**
    Allows the Shop owner to remove items.

    @param _itemId The id of the specific inventory item of this shop to remove.
    @param _amount The amount of the specified item to remove.
  */
  function removeItem(uint256 _itemId, uint256 _amount) external nonReentrant onlyOwner {
    ShopItem storage item = inventory[_itemId];
    require(item.amount >= _amount && item.amount != 0,
      "There is not enough of your desired item to remove.");
    inventory[_itemId].amount = inventory[_itemId].amount.sub(_amount);
    item.token.safeTransferFrom(address(this), msg.sender, item.id, _amount, "");
  }

  /**
    Allows the Shop owner to adjust the prices of an NFT item set.

    @param _itemId The id of the specific inventory item of this shop to adjust.
    @param _pricePairs The asset-price pairs at which to sell a single instance of the item.
  */
  function changeItemPrice(uint256 _itemId, PricePair[] memory _pricePairs) external onlyOwner {
    for (uint i = 0; i < _pricePairs.length; i++) {
      prices[_itemId][i] = _pricePairs[i];
    }
    pricePairLengths[_itemId] = _pricePairs.length;
  }

  /**
    Allows any user to purchase an item from this Shop provided they have enough
    of the asset being used to purchase with.

    @param _itemId The ID of the specific inventory item of this shop to buy.
    @param _amount The amount of the specified item to purchase.
    @param _assetId The index of the asset from the item's asset-price pairs to
                    attempt this purchase using.
  */
  function purchaseItem(uint256 _itemId, uint256 _amount, uint256 _assetId) external nonReentrant payable {
    ShopItem storage item = inventory[_itemId];
    require(item.amount >= _amount && item.amount != 0,
      "There is not enough of your desired item in stock to purchase.");
    require(_assetId < pricePairLengths[_itemId],
      "Your specified asset ID is not valid.");
    PricePair memory sellingPair = prices[_itemId][_assetId];

    // If the sentinel value for the point asset type is found, sell for points.
    // This involves converting the asset from an address to a Staker index.
    if (sellingPair.assetType == 0) {
      uint256 stakerIndex = uint256(sellingPair.asset);
      stakers[stakerIndex].spendPoints(msg.sender, sellingPair.price.mul(_amount));
      inventory[_itemId].amount = inventory[_itemId].amount.sub(_amount);
      item.token.safeTransferFrom(address(this), msg.sender, item.id, _amount, "");

    // If the sentinel value for the Ether asset type is found, sell for Ether.
    } else if (sellingPair.assetType == 1) {
      uint256 etherPrice = sellingPair.price.mul(_amount);
      require(msg.value >= etherPrice,
        "You did not send enough Ether to complete this purchase.");
      uint256 feePercent = feeOwner.fee();
      uint256 feeValue = msg.value.mul(feePercent).div(100000);
      uint256 itemRoyaltyPercent = item.token.feeOwner().fee();
      uint256 royaltyValue = msg.value.mul(itemRoyaltyPercent).div(100000);
      (bool success, ) = payable(feeOwner.owner()).call{ value: feeValue }("");
      require(success, "Platform fee transfer failed.");
      (success, ) = payable(item.token.feeOwner().owner()).call{ value: royaltyValue }("");
      require(success, "Creator royalty transfer failed.");
      (success, ) = payable(owner()).call{ value: msg.value.sub(feeValue).sub(royaltyValue) }("");
      require(success, "Shop owner transfer failed.");
      inventory[_itemId].amount = inventory[_itemId].amount.sub(_amount);
      item.token.safeTransferFrom(address(this), msg.sender, item.id, _amount, "");

    // Otherwise, attempt to sell for an ERC20 token.
    } else {
      IERC20 sellingAsset = IERC20(sellingPair.asset);
      uint256 tokenPrice = sellingPair.price.mul(_amount);
      require(sellingAsset.balanceOf(msg.sender) >= tokenPrice,
        "You do not have enough token to complete this purchase.");
      uint256 feePercent = feeOwner.fee();
      uint256 feeValue = tokenPrice.mul(feePercent).div(100000);
      uint256 itemRoyaltyPercent = item.token.feeOwner().fee();
      uint256 royaltyValue = tokenPrice.mul(itemRoyaltyPercent).div(100000);
      sellingAsset.safeTransferFrom(msg.sender, feeOwner.owner(), feeValue);
      sellingAsset.safeTransferFrom(msg.sender, item.token.feeOwner().owner(), royaltyValue);
      sellingAsset.safeTransferFrom(msg.sender, owner(), tokenPrice.sub(feeValue).sub(royaltyValue));
      inventory[_itemId].amount = inventory[_itemId].amount.sub(_amount);
      item.token.safeTransferFrom(address(this), msg.sender, item.id, _amount, "");
    }
  }
}