// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";

contract PhynomNFTMarketplace is ReentrancyGuard,Ownable {
  using Counters for Counters.Counter;
  using SafeMath for uint256;
  Counters.Counter public _itemIds;
  Counters.Counter public _itemsSold;

  uint256 constant public TOTAL_PERC = 1000;

  uint256 public listingFee = 25; //2.5%

  address public nftContractAddress;

  constructor(address _nftContract) {
    nftContractAddress = _nftContract;
  }

  struct MarketItem {
    uint itemId;
    address nftContract;
    uint256 tokenId;
    address payable seller;
    address payable owner;
    uint256 price;
    bool sold;
    bool isOnAuction;
    uint256 bidEndTime;
  }

  struct Bidder{
    uint256 amount;
    address bidderAddr;
  }

  mapping(uint256 => MarketItem) public idToMarketItem;
  mapping(uint256=>uint256) public tokenIdToItemId;
  mapping(uint256=>Bidder) public highestBidderMapping;
  uint256 public totalAmountDue;

  event MarketItemCreated (
    uint indexed itemId,
    address indexed nftContract,
    uint256 indexed tokenId,
    address seller,
    address owner,
    uint256 price,
    bool sold
  );

  struct RoyalityData{
    uint256 tokenId;
    address creator;
    uint256 royalityPercentage;
  }

  mapping(uint256=>RoyalityData) public idToRoyalityData;

  /* Returns the listing price of the contract */
  function getListPercentage() external view returns (uint256) {
    return listingFee;
  }

  /* Places an item for sale on the marketplace */
  function createMarketItem(
    uint256 tokenId,
    uint256 price,
    uint256 royalityPerc,
    bool _isOnAuction,
    uint256 _bidEndTime
  ) external nonReentrant {
    require(price > 0, "Price must be at least 1 wei");
    require(royalityPerc<=100,"Royality cannot be greater than 10%");
    require(!_isOnAuction || _bidEndTime>block.timestamp,"Bid end time must be greater than current time");
    require(IERC721(nftContractAddress).ownerOf(tokenId)==msg.sender,"You are not owner of this nft");
    require(IERC721(nftContractAddress).isApprovedForAll(msg.sender,address(this)) ||
      IERC721(nftContractAddress).getApproved(tokenId)==address(this) 
    ,"Current Item is not approved");
    _itemIds.increment();
    uint256 itemId = _itemIds.current();
    tokenIdToItemId[tokenId] = itemId;
    address royalityReceiver;
    if(royalityPerc>0){
      royalityReceiver = msg.sender;
    }

    if(idToRoyalityData[tokenId].creator!=address(0)){
      royalityReceiver = idToRoyalityData[tokenId].creator;
      royalityPerc = idToRoyalityData[tokenId].royalityPercentage;
    }else{
      royalityReceiver = msg.sender;
      idToRoyalityData[tokenId].creator=msg.sender;
      idToRoyalityData[tokenId].royalityPercentage=royalityPerc;
    }

    idToMarketItem[itemId] =  MarketItem(
      itemId,
      nftContractAddress,
      tokenId,
      payable(msg.sender),
      payable(address(0)),
      price,
      false,
      _isOnAuction,
      _bidEndTime
    );


    emit MarketItemCreated(
      itemId,
      nftContractAddress,
      tokenId,
      msg.sender,
      address(0),
      price,
      false
    );
  }

  /* Creates the sale of a marketplace item */
  /* Transfers ownership of the item, as well as funds between parties */
  function createMarketSale(
    uint256 itemId
    ) external payable nonReentrant {
    uint price = idToMarketItem[itemId].price;
    uint tokenId = idToMarketItem[itemId].tokenId;
    require(IERC721(nftContractAddress).isApprovedForAll(idToMarketItem[itemId].seller,address(this)) ||
      IERC721(nftContractAddress).getApproved(tokenId)==address(this)
    ,"Current Item is not approved");
    require(!idToMarketItem[itemId].isOnAuction,"Cannot buy directly");
    require(!idToMarketItem[itemId].sold,"Already sold");
    require(msg.value == price, "Please submit the asking price in order to complete the purchase");
    require(msg.sender!=idToMarketItem[itemId].seller,"Already owned");
    uint256 royalityAmount = 0;

    if(idToRoyalityData[tokenId].royalityPercentage>0 && idToRoyalityData[tokenId].creator!=address(0)){
      royalityAmount = (price*idToRoyalityData[tokenId].royalityPercentage)/TOTAL_PERC;
      console.log("royalityAmount",royalityAmount);
        payable(idToRoyalityData[tokenId].creator).transfer(royalityAmount);
    }

    uint256 listFee = (price * listingFee)/TOTAL_PERC;

    uint256 remaining = price - royalityAmount - listFee;
    console.log("remaining",remaining); 
    idToMarketItem[itemId].seller.transfer(remaining);
    IERC721(nftContractAddress).transferFrom(idToMarketItem[itemId].seller, msg.sender, tokenId);
    idToMarketItem[itemId].owner = payable(msg.sender);
    idToMarketItem[itemId].sold = true;

    _itemsSold.increment();
  }

  function createBidOnItem(
    uint256 itemId
    ) external payable nonReentrant {
     uint price = idToMarketItem[itemId].price;
    uint tokenId = idToMarketItem[itemId].tokenId;
    require(IERC721(nftContractAddress).isApprovedForAll(idToMarketItem[itemId].seller,address(this)) ||
      IERC721(nftContractAddress).getApproved(tokenId)==address(this)
    ,"Current Item is not approved");
    require(idToMarketItem[itemId].isOnAuction,"Item is not on auction");
    require(idToMarketItem[itemId].bidEndTime>block.timestamp,"Auction time ended");
    require(!idToMarketItem[itemId].sold,"Already sold");
    require(msg.sender!=idToMarketItem[itemId].seller,"Already owned");
    require(msg.value >= price && msg.value > highestBidderMapping[itemId].amount, "Bid price must be greater than base price and highest bid");

    if(highestBidderMapping[itemId].bidderAddr!=address(0)){
      payable(highestBidderMapping[itemId].bidderAddr).transfer(highestBidderMapping[itemId].amount);
      totalAmountDue = totalAmountDue.sub(highestBidderMapping[itemId].amount);
    }
    totalAmountDue = totalAmountDue.add(msg.value);
    highestBidderMapping[itemId] = Bidder({
      amount:msg.value,
      bidderAddr:msg.sender
    });
  }

  function claimBidItem(uint256 itemId) external nonReentrant {
    require(idToMarketItem[itemId].isOnAuction,"Item is not on auction");
    require(idToMarketItem[itemId].bidEndTime<=block.timestamp,"Bidding is still in progress");
    uint tokenId = idToMarketItem[itemId].tokenId;
    require(IERC721(nftContractAddress).isApprovedForAll(idToMarketItem[itemId].seller,address(this)) ||
      IERC721(nftContractAddress).getApproved(tokenId)==address(this)
    ,"Current Item is not approved");
    require(msg.sender!=idToMarketItem[itemId].seller,"Already owned");
    require(highestBidderMapping[itemId].bidderAddr==msg.sender,"Only highest bidder can claim the NFT");
    
    uint256 royalityAmount = 0;
    uint256 price = highestBidderMapping[itemId].amount;

    if(idToRoyalityData[tokenId].royalityPercentage>0 && idToRoyalityData[tokenId].creator!=address(0)){
      royalityAmount = (price*idToRoyalityData[tokenId].royalityPercentage)/TOTAL_PERC;
      console.log("royalityAmount",royalityAmount);
      payable(idToRoyalityData[tokenId].creator).transfer(royalityAmount);
    }
    
    uint256 listFee = (price * listingFee)/TOTAL_PERC;

    uint256 remaining = price - royalityAmount - listFee;
    console.log("remaining",remaining); 
    idToMarketItem[itemId].seller.transfer(remaining);
    totalAmountDue = totalAmountDue.sub(price);
    IERC721(nftContractAddress).transferFrom(idToMarketItem[itemId].seller, msg.sender, tokenId);
    idToMarketItem[itemId].owner = payable(msg.sender);
    idToMarketItem[itemId].sold = true;

    _itemsSold.increment();
  }

  /* Returns all unsold market items */
  function fetchMarketItems() external view returns (MarketItem[] memory) {
    uint itemCount = _itemIds.current();
    uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
    uint currentIndex = 0;

    MarketItem[] memory items = new MarketItem[](unsoldItemCount);
    for (uint i = 0; i < itemCount; i++) {
      if (idToMarketItem[i + 1].owner == address(0)) {
        uint currentId = i + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }

  /* Returns onlyl items that a user has purchased */
  function fetchMyNFTs(address userAddress) external view returns (MarketItem[] memory) {
    uint totalItemCount = _itemIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;

    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].owner == userAddress) {
        itemCount += 1;
      }
    }

    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].owner == userAddress) {
        uint currentId = i + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }

  /* Returns only items a user has created */
  function fetchItemsCreated(address userAddress) external view returns (MarketItem[] memory) {
    uint totalItemCount = _itemIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;

    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].seller == userAddress) {
        itemCount += 1;
      }
    }

    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].seller == userAddress) {
        uint currentId = i + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }

  function currentItemID() public view returns (uint256) {
    return _itemIds.current();
  }

  function currentSoldID() public view returns (uint256) {
    return _itemsSold.current();
  }

  function changeNftContractAddress(address _newNftContract) external onlyOwner{
    require(_newNftContract!=nftContractAddress,"New address cannot be same with previous address");
    nftContractAddress = _newNftContract;
  }

  function getOwnerBalance() public view returns(uint256){
    uint256 amount = address(this).balance.sub(totalAmountDue);
    console.log("amount",amount);
    return amount;
  }

  function getBalance() public view returns(uint256){
    return address(this).balance;
  }

  function withdraw() external onlyOwner{
    uint256 amount = address(this).balance.sub(totalAmountDue);
    require(amount>0,"Cannot withdraw at this time");
    console.log("amount",amount);
    payable(msg.sender).transfer(amount);
  }

    function setListingPercentage(uint256 _listingPercentage) external onlyOwner {
      require(listingFee != _listingPercentage,"New listing percentage cannot be same with previous listing percentage");
      require(_listingPercentage<=200,"Invalid percentage");
      listingFee = _listingPercentage;
    }
}