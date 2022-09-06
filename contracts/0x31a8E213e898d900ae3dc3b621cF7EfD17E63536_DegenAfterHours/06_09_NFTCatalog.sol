//SPDX-License-Identifier: MIT
/*
 ██████  ██████  ███    ███ ██  ██████ ██████   ██████  ██   ██ ███████ ██      ███████ 
██      ██    ██ ████  ████ ██ ██      ██   ██ ██    ██  ██ ██  ██      ██      ██      
██      ██    ██ ██ ████ ██ ██ ██      ██████  ██    ██   ███   █████   ██      ███████ 
██      ██    ██ ██  ██  ██ ██ ██      ██   ██ ██    ██  ██ ██  ██      ██           ██ 
 ██████  ██████  ██      ██ ██  ██████ ██████   ██████  ██   ██ ███████ ███████ ███████ 
*/                                                                           
pragma solidity ^0.8.15;
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTCatalog is Ownable {
  //database
  struct ITEM {
    uint256 price;
    uint16 quantity;
  }

  mapping(string => ITEM) catalog;
  mapping(uint256 => string) tokenIdToSKU;
  mapping(string => uint256[]) skuToTokenIds;

  error SKUDoesNotExist();
  error SKUEmpty();
  error SKUsMustMatchItems();
  error InsufficientQuantity(uint16 quantity);

  /**
    Catalog functions
   */

  ///@dev handle multiple tokens' quantity, and record tokenIds
  function recordMintedTokens(string memory sku, uint256 startTokenId, uint16 quantity) internal {
    if(catalog[sku].quantity < quantity) revert InsufficientQuantity({quantity: catalog[sku].quantity});
    catalog[sku].quantity -= quantity;
    for(uint256 i = startTokenId; i < startTokenId + quantity; i++) {
      tokenIdToSKU[i] = sku;
      skuToTokenIds[sku].push(i);
    }
  }

  ///@dev add single item to catalog
  function addItem(string memory sku, ITEM memory item) public onlyOwner {
    if(bytes(sku).length == 0) revert SKUEmpty();
    catalog[sku] = item;
  }

  ///@dev add multiple items to catalog
  function addItems(string[] memory skus, ITEM[] memory items) public onlyOwner {
    if(skus.length != items.length) revert SKUsMustMatchItems();
    for(uint i = 0; i < items.length; i++) {
      if(bytes(skus[i]).length == 0) revert SKUEmpty();
      catalog[skus[i]] = items[i];
    }
  }

  ///@dev deactivates an item by setting its quantity to 0
  function deactivateItem(string memory sku) public onlyOwner {
    getItemBySku(sku);  //check existence
    catalog[sku].quantity = 0;
  }

  ///@dev return item quantity and price by SKU
  function getItemBySku(string memory sku) public view returns(ITEM memory) {
    if(bytes(sku).length == 0) revert SKUEmpty();
    if(catalog[sku].price == 0 && catalog[sku].quantity == 0) revert SKUDoesNotExist();
    return catalog[sku];
  }

  ///@dev return SKU by token id
  function getSkuByTokenId(uint256 tokenId) public view returns (string memory) {
    return tokenIdToSKU[tokenId];
  }

  ///@dev get all token ids that have the same SKU
  function getTokenIdsBySku(string memory sku) public view returns (uint256[] memory) {
    return skuToTokenIds[sku];
  } 
}