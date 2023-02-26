/*
    Copyright 2023, Abdullah Al-taheri عبدالله الطاهري (المُعلَّقَاتٌ - muallaqat.io - muallaqat.eth - معلقات.eth)

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/// @title MuallaqatNFTMarket Contract 
/// @author Abdullah Al-taheri


pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./library/@rarible/royalties/contracts/LibPart.sol";
import "./library/@rarible/royalties/contracts/LibRoyaltiesV2.sol";
import "./Tokens/MuallaqatNFT.sol";


contract MuallaqatNFTMarket is Ownable, Pausable {

  using Counters for Counters.Counter;
  Counters.Counter private _itemIds;
  Counters.Counter private _itemsSold;

  uint256 ListingAndFeesPrice; 
  uint256 premiumFees;
  uint256 premiumDays;
  uint256 ownerPercentage;
  address MuallaqatNFTAddress;

  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  /* STRINGS */
  string private constant _NOT_OWNER = "You are not the owner of this item";
  string private constant _NOT_ON_SALE = "Item is not on sale";
  string private constant _NOT_ON_HOLD = "Item is not on hold";
  string private constant _PRICE_TOO_LOW = "Price must be at least 1 wei";
  string private constant _PRICE_NOT_EQUAL_TO_PREMIUM_FEES = "Price must be equal to premium fees";
  string private constant _PRICE_NOT_EQUAL_TO_FEES = "Price must be equal to listing price";
  string private constant _INVALID_ITEM = "Please chose a vaild item";
  string private constant _ITEM_NOT_ON_SALE = "Item Not on Sale";
  string private constant _ITEM_ON_SALE = "Item is on sale";
  string private constant _PRICE_NOT_CORRECT = "Price is not correct";
  string private constant _NOT_ENOUGH_FEES = "Please send the Fees in order to complete the process";
  string private constant _ITEM_ALREADY_PREMIUM = "Item is already premium";
  string private constant _ROYALTIES_NOT_SUPPORTED = "NFT contract must support royalties";

  enum Status{ onSale,onHold,Sold,Canceled }
  enum contractTypes  {SCRIPT,ART,MUSIC,DOMAIN,MAPS,NICKNAME}

  struct MarketItem {
    uint256 itemId; // sale item id
    uint256 tokenId; // tokenId of the NFT
    address tokenContract; // contract of token
    contractTypes contractType;
    uint256 salePrice; // sale price
    Status status; // sale status;
    uint256 listingDate; // listing date
    uint256 expiringDate; // expiring date
    address payable owner; // owner of the token
    bool premium; // premium
  }

  mapping(uint256 => MarketItem) private idToMarketItem;
  
  event MarketItemUpgraded(
    uint256 tokenId,
    address contractAddress,
    address owner
  );

  event MarketItemCreated (
    uint256 itemId,
    uint256 tokenId,
    uint256 salePrice,
    address seller,
    address contractAddress
  
  );
  event MarketSale (
    uint256 itemId,
    uint256 tokenId,
    address contractAddress,
    address seller,
    uint256 salePrice,
    address buyer
  );
  event MarketItemStatusChanged (
    uint256 itemId,
    uint256 tokenId,
    address contractAddress,
    address owner,
    Status status
  );
  event MarketItemPriceChanged (
    uint256 itemId,
    uint256 tokenId,
    address contractAddress,
    address owner,
    uint256 oldPrice,
    uint256 newPrice
  );
  

  constructor() {
    ListingAndFeesPrice = 0.001 ether; 
    premiumFees = 0.1 ether;
    premiumDays = 30;
    ownerPercentage = 100; // 1% to muallaqat <3
  }
  
  // get all fees as array 
  function getFees() public view returns (uint256[] memory) {
    uint256[] memory fees = new uint256[](5);
    fees[0] = ListingAndFeesPrice;
    fees[1] = premiumFees;
    fees[2] = premiumDays;
    fees[3] = ownerPercentage;
    return fees;
  }
  // owner FUNCTIONS
  function setListingFees(uint256 _price) public onlyOwner  {
    ListingAndFeesPrice = _price;
  }
  function setMuallaqatNFTAddress(address _address) public onlyOwner  {
    MuallaqatNFTAddress = _address;
  }

  // create functions
  function createMuallaqatMarketItem(
    string memory tokenURI,
    // price in wei
    uint256 price,
    bool premium,
    uint96 royalties,
    string memory script,
    uint96  script_type,
    uint96  contractType
  ) public payable whenNotPaused{
    
    require(price > 0, _PRICE_TOO_LOW);
    uint256 premiumExpiringDate = 0;
    if(premium){
      require(msg.value == premiumFees, _PRICE_NOT_EQUAL_TO_PREMIUM_FEES);
      premiumExpiringDate = block.timestamp + (86400 * premiumDays);
    }else{
      require(msg.value == ListingAndFeesPrice, _PRICE_NOT_EQUAL_TO_FEES);
    }
    payable(owner()).transfer(msg.value);

    uint256 itemId;
    _itemIds.increment();
    itemId = _itemIds.current();
    uint256 listingDate = block.timestamp;
    uint256 tokenId = MuallaqatNFT(MuallaqatNFTAddress).createToken(tokenURI,script,script_type);
    if(royalties>0)
      MuallaqatNFT(MuallaqatNFTAddress).setRoyalties(tokenId,payable(msg.sender),royalties);
    
    idToMarketItem[itemId] =  MarketItem(
        itemId,
        tokenId,
        MuallaqatNFTAddress,
        contractTypes(contractType),
        price,
        Status.onSale,
        listingDate,
        premiumExpiringDate,
        payable(msg.sender),
        premium 
    );
    
    emit MarketItemCreated(
        itemId,
        tokenId,
        price,
        msg.sender,
        MuallaqatNFTAddress
    );
  
  }
  function createMarketItem(
    address nftContract,
    uint256 tokenId,
    // price in wei
    uint256 price,
    bool premium,
    uint96 nftContractType
  ) public payable  whenNotPaused{
    require(
      MuallaqatNFT(nftContract).supportsInterface(LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) 
      || 
      MuallaqatNFT(nftContract).supportsInterface(_INTERFACE_ID_ERC2981), 
    _ROYALTIES_NOT_SUPPORTED);
    require(price > 0, _PRICE_TOO_LOW);
    uint256 premiumExpiringDate = 0;
    if(premium){
      require(msg.value == premiumFees, _PRICE_NOT_EQUAL_TO_PREMIUM_FEES);
      premiumExpiringDate = block.timestamp + (86400 * premiumDays);
    }else{
      require(msg.value == ListingAndFeesPrice, _PRICE_NOT_EQUAL_TO_FEES);
    }
    payable(owner()).transfer(msg.value);

    uint256 listingDate = block.timestamp;
    uint256 itemId;
    _itemIds.increment();
    itemId = _itemIds.current();
    idToMarketItem[itemId] =  MarketItem(
        itemId,
        tokenId,
        nftContract,
        contractTypes(nftContractType),
        price,
        Status.onSale,
        listingDate,
        premiumExpiringDate,
        payable(msg.sender),
        premium 
    );

    ERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
   
    emit MarketItemCreated(
        itemId,
        tokenId,
        price,
        msg.sender,
        nftContract
    );
  }
  
  function createMarketSale(
    uint256 itemId
    ) public payable  whenNotPaused {
    require(idToMarketItem[itemId].itemId !=0 ,_INVALID_ITEM);
    require(idToMarketItem[itemId].status == Status.onSale,_ITEM_NOT_ON_SALE);
    require(msg.value >= idToMarketItem[itemId].salePrice,_PRICE_NOT_CORRECT);

    
    uint tokenId = idToMarketItem[itemId].tokenId;
    uint amount = msg.value ;
    // owner get 1% from sale price
    payable(owner()).transfer(amount * ownerPercentage /10000);
    amount -= amount * ownerPercentage/10000;


    // royalties
    if(MuallaqatNFT(idToMarketItem[itemId].tokenContract).supportsInterface(LibRoyaltiesV2._INTERFACE_ID_ROYALTIES)){
      LibPart.Part[] memory _royalties = MuallaqatNFT(idToMarketItem[itemId].tokenContract).getRaribleV2Royalties(tokenId);
      for(uint i = 0; i < _royalties.length; i++){
          uint256 royalties = amount * _royalties[i].value /10000;
          payable(_royalties[i].account).transfer(royalties);

         amount = amount - royalties;
      }


    }else if(MuallaqatNFT(idToMarketItem[itemId].tokenContract).supportsInterface(_INTERFACE_ID_ERC2981)){
      address account;
      uint precent;
      (account,precent)= MuallaqatNFT(idToMarketItem[itemId].tokenContract).royaltyInfo(tokenId,amount);
     
      uint256 royalties = amount * precent/100;
      payable(account).transfer(royalties);
    
      amount = amount - royalties;
    }
    
    // transfer amount to nft owner
    idToMarketItem[itemId].owner.transfer(amount);

    idToMarketItem[itemId].status = Status.Sold;
    address prev_owner = idToMarketItem[itemId].owner;
    idToMarketItem[itemId].owner = payable(msg.sender);

    // transfer nft to buyer
    MuallaqatNFT(idToMarketItem[itemId].tokenContract).transferFrom(address(this), msg.sender, tokenId);
    _itemsSold.increment();

   emit MarketSale(
      itemId,
      tokenId,
      idToMarketItem[itemId].tokenContract,
      prev_owner,
      idToMarketItem[itemId].salePrice,
      msg.sender
    );
    
   emit MarketItemStatusChanged(
      itemId,
      tokenId,
      idToMarketItem[itemId].tokenContract,
      prev_owner,
      idToMarketItem[itemId].status
    );
 
  }

  // list
  function listItem(uint256 itemId, uint256 newPrice) public payable  whenNotPaused {
    require(idToMarketItem[itemId].itemId !=0 ,_INVALID_ITEM);
    // only if not on sale
    require(idToMarketItem[itemId].status != Status.onSale,_ITEM_ON_SALE);
    // only owner of item 
    require(idToMarketItem[itemId].owner == msg.sender,_NOT_OWNER);
    require(msg.value == ListingAndFeesPrice , _NOT_ENOUGH_FEES);
    payable(owner()).transfer(msg.value);
   
    emit MarketItemStatusChanged(
      itemId,
      idToMarketItem[itemId].tokenId,
      idToMarketItem[itemId].tokenContract,
      msg.sender,
      Status.onSale
    );
    if(newPrice !=idToMarketItem[itemId].salePrice){
      emit MarketItemPriceChanged(
        itemId,
        idToMarketItem[itemId].tokenId,
        idToMarketItem[itemId].tokenContract,
        msg.sender,
        idToMarketItem[itemId].salePrice,
        newPrice
      );
    }
    ERC721(idToMarketItem[itemId].tokenContract).transferFrom(msg.sender, address(this), idToMarketItem[itemId].tokenId);
    idToMarketItem[itemId].salePrice = newPrice;
    idToMarketItem[itemId].status = Status.onSale;
  }
  // unlist itemId
  function unlistItem(uint256 itemId) public payable  whenNotPaused {
    require(idToMarketItem[itemId].itemId !=0 ,_INVALID_ITEM);
    /// if contract owner or owner of item
    require(msg.sender == owner() || idToMarketItem[itemId].owner == msg.sender,_NOT_OWNER);
    //ListingAndFeesPrice
    require(msg.value == ListingAndFeesPrice , _NOT_ENOUGH_FEES);
    // only if on sale
    require(idToMarketItem[itemId].status == Status.onSale,_NOT_ON_SALE);
    // return token to owner
    MuallaqatNFT(idToMarketItem[itemId].tokenContract).transferFrom(address(this), idToMarketItem[itemId].owner, idToMarketItem[itemId].tokenId);

    // change status to canceled
    idToMarketItem[itemId].status = Status.Canceled;
    emit MarketItemStatusChanged(
      itemId,
      idToMarketItem[itemId].tokenId,
      idToMarketItem[itemId].tokenContract,
      msg.sender,
      Status.Canceled
    );
  }
  // upgrade Item
  function upgradeItem(uint256 itemId) public payable whenNotPaused {
    require(idToMarketItem[itemId].status == Status.onSale,_NOT_ON_SALE);
    require(idToMarketItem[itemId].owner == msg.sender,_NOT_OWNER);
    require(idToMarketItem[itemId].premium == false, _ITEM_ALREADY_PREMIUM);
    require(msg.value == premiumFees, _NOT_ENOUGH_FEES);
    payable(owner()).transfer(msg.value);

    MarketItem memory item = idToMarketItem[itemId];
    item.expiringDate = block.timestamp + (86400 * premiumDays);
    item.premium = true;
    idToMarketItem[itemId] = item;
    emit MarketItemUpgraded(
      idToMarketItem[itemId].tokenId,
      idToMarketItem[itemId].tokenContract,
      msg.sender
    );
  }
  
  // change market item price 
  function setBuyPrice(uint256 itemId, uint256 newPrice) public payable  whenNotPaused {
    require(idToMarketItem[itemId].itemId !=0 ,_INVALID_ITEM);
    require(idToMarketItem[itemId].status == Status.onSale,_NOT_ON_SALE);
    require(idToMarketItem[itemId].owner == msg.sender,_NOT_OWNER);
    require(msg.value >= ListingAndFeesPrice , _NOT_ENOUGH_FEES);

    payable(owner()).transfer(msg.value);
    emit MarketItemPriceChanged(
      itemId,
      idToMarketItem[itemId].tokenId,
      idToMarketItem[itemId].tokenContract,
      msg.sender,
      idToMarketItem[itemId].salePrice,
      newPrice
    );
    idToMarketItem[itemId].salePrice = newPrice;
  }
  
  function balance() public view returns(uint accountBalance)
  {
    accountBalance = address(this).balance;
    return accountBalance;
  }

  function fetchMarketItemsLimit(uint offset,uint96 _type) public view returns (MarketItem[] memory) {
    uint limit = _itemIds.current() - offset;
    uint currentIndex = 0;

    MarketItem[] memory items = new MarketItem[](limit);
    for (uint i = offset; i < limit; i++) {
      if (_type == 99 || idToMarketItem[i + 1].status == Status(_type)) {
        uint currentId = i + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
   
    return items;
  }
 
  // get length of market items
  function getMarketItemsLength() public view returns (uint) {
    return _itemIds.current();
  }
  function getMarketItem(uint256 marketItemId) public view returns (MarketItem memory) {
    return idToMarketItem[marketItemId];
  }
}