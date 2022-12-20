// SPDX-License-Identifier: MIT
/**
*This Agreement (“Agreement”) is made the day when the individual (hereinafter referred
*to as “the Donor”) initiates this electronic self-executing program (“smart contract”) by
*purchasing a Non-Fungible Token (“NFT”) from ZONGO KIDS MOVEMENT DAO (“ZKM
*DAO), The Donor and ZKM DAO agree as follows:
*
*Donor Commitment. The Donor hereby contributes to ZKM DAO the sum of 37.5% of
*the purchase price of the NFT sold on ZKM DAO’s website (“Zongo.xyz”) as per the
*distribution of funds executed by this smart contract, which as provided for herein is designated
*for the benefit of ZKM DAO charitable Endowment.
*If the Donor sells the NFT, 5% of the sale price will be contributed to ZKM DAO for the
*ZKM DAO Charitable Endowment.
*
*Donor Purpose. Purpose. It is understood and agreed that the gift will be used for the
*following purpose or purposes: 25% of the purchase price will be going to ZKM DAO Treasury,
*which is primary use is for providing assistance for individuals in need. 12.5% of the purchase
*price will be used for special community initiatives set forth by ZKM DAO.
*
*Payment. It is further understood and agreed that the contribution will be paid when the
*Donor has purchased the NFT from Zongo.xyz. Contributions to ZKM DAO are considered as
*being tax deductible contributions as per IRC 501(c)(3).
*/
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "hardhat/console.sol";

contract NFTMarketplace is ERC721URIStorage {
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIds;
  Counters.Counter private _itemsSold;

  uint256 listingPrice = 0.0 ether;

  address payable owner;

  mapping(uint256 => MarketItem) private idToMarketItem;

  struct MarketItem {
   uint256 tokenId;
   address payable seller;
   address payable owner;
   uint256 price;
   bool sold;
  }

  event MarketItemCreated (
    uint256 indexed tokenId,
    address seller,
    address owner,
    uint256 price,
    bool sold
  );

  constructor() ERC721("ZKM Tokens", "ZKM") {
    owner = payable(msg.sender);
  }

  function updateListingPrice (uint _listingPrice) public payable {
    require(owner == msg.sender, "Only marketplace owner can update the listing price");

    listingPrice = _listingPrice;
  }

  function getListingPrice() public view returns (uint256) {
    return listingPrice;
  }

  function createToken(string memory tokenURI, uint256 price) public payable returns (uint) {
    _tokenIds.increment();

    uint256 newTokenId = _tokenIds.current();

    _mint(msg.sender, newTokenId);
    _setTokenURI(newTokenId, tokenURI);

    createMarketItem(newTokenId, price);

    return newTokenId;
  }

  function createMarketItem(uint256 tokenId, uint256 price) private {
    require(price > 0, "Price must be at least 1");
    require(msg.value == listingPrice, "Price must be equal to listing price");

    idToMarketItem[tokenId] = MarketItem(
      tokenId,
      payable(msg.sender),
      payable(address(this)),
      price,
      false
    );

    _transfer(msg.sender, address(this), tokenId);

    emit MarketItemCreated(tokenId, msg.sender, address(this), price, false);
  }

  function resellToken(uint256 tokenId, uint256 price) public payable {
    require(idToMarketItem[tokenId].owner == msg.sender, "Only item owner can perform this operation");
    require(msg.value == listingPrice, "Price must be equal to listing price");

    idToMarketItem[tokenId].sold = false;
    idToMarketItem[tokenId].price = price;
    idToMarketItem[tokenId].seller = payable(msg.sender);
    idToMarketItem[tokenId].owner = payable(address(this));

    _itemsSold.decrement();

    _transfer(msg.sender, address(this), tokenId);
  }

  function createMarketSale(uint256 tokenId) public payable {
    uint price = idToMarketItem[tokenId].price;
    address seller = idToMarketItem[tokenId].seller;

    require(msg.value == price, "Please submit the asking price in order to complete the purchase");

    idToMarketItem[tokenId].owner = payable(msg.sender);
    idToMarketItem[tokenId].sold = true;
    idToMarketItem[tokenId].seller = payable(address(0));

    _itemsSold.increment();

    _transfer(address(this), msg.sender, tokenId);

    //(payable(owner).transfer(msg.value / 2); payable(idToMarketItem[tokenId].seller).transfer(msg.value * (100-feepercent)/100);)

    payable(owner).transfer(msg.value / 2);
    payable(seller).transfer(msg.value / 2);
  }

  function fetchMarketItems() public view returns (MarketItem [] memory) {
    uint itemCount = _tokenIds.current();
    uint unsoldItemCount = _tokenIds.current() - _itemsSold.current();
    uint currentIndex = 0;

    MarketItem[] memory items = new MarketItem[](unsoldItemCount);

    for(uint i = 0; i < itemCount; i++) {
      if(idToMarketItem[i + 1].owner == address(this)) {
        uint currentId = i + 1;

        MarketItem storage currentItem = idToMarketItem[currentId];

        items[currentIndex] = currentItem;

        currentIndex += 1;
      }
    }


    return items;
  }

  function fetchMyNFTs() public view returns (MarketItem[] memory) {
    uint totalItemCount = _tokenIds.current ();
    uint itemCount = 0;
    uint currentIndex = 0;

    for(uint i = 0; i < totalItemCount; i++) {
      if(idToMarketItem[i + 1].owner == msg.sender) {
        itemCount += 1;
      }
    }

    MarketItem[] memory items = new MarketItem[](itemCount);

    for(uint i = 0; i < totalItemCount; i++) {
      if(idToMarketItem[i + 1].owner == msg.sender) {
        uint currentId = i + 1;

        MarketItem storage currentItem = idToMarketItem[currentId];

        items[currentIndex] = currentItem;

        currentIndex += 1;
      }
    }


    return items;
  }

  function fetchItemsListed() public view returns (MarketItem[] memory) {
    uint totalItemCount = _tokenIds.current ();
    uint itemCount = 0;
    uint currentIndex = 0;

    for(uint i = 0; i < totalItemCount; i++) {
      if(idToMarketItem[i + 1].seller == msg.sender) {
        itemCount += 1;
      }
    }

    MarketItem[] memory items = new MarketItem[](itemCount);

    for(uint i = 0; i < totalItemCount; i++) {
      if(idToMarketItem[i + 1].seller == msg.sender) {
        uint currentId = i + 1;

        MarketItem storage currentItem = idToMarketItem[currentId];

        items[currentIndex] = currentItem;

        currentIndex += 1;
      }
    }

    return items;
  }
}