//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import "hardhat/console.sol";


contract NFTMarket is ReentrancyGuard {

    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;

    address payable owner;
    uint256 listingPrice = 0.001 ether;

    constructor(){
        owner = payable(msg.sender);
    }

    struct MarketItem {
        uint itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }


    mapping(uint256 => MarketItem) private idToMarketItem;

    event MarketItemCreated (
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );



    function getListingPrice() public view returns(uint256) {
        return listingPrice;
    }

    function updateListingPrice(uint256 _listPrice) public payable {

        require(owner == msg.sender, "Only owner can update the listing price");
        listingPrice = _listPrice;

    }

    function createMarketItem(address nftContract, uint256 tokenId, uint256 price) public payable nonReentrant{
        require(price > 0, "Price must be at least 1 wei");

        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        idToMarketItem[itemId] = MarketItem(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            false
        );
        
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        emit MarketItemCreated(
            itemId, 
            nftContract, 
            tokenId, 
            msg.sender, 
            address(0), 
            price, 
            false
        );

    }

    function createMarketReItem(address nftContract, uint256 itemId, uint256 price) public payable nonReentrant{
        require(price > 0, "Price must be at least 1 wei");

        uint tokenId = idToMarketItem[itemId].tokenId;

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);  

        idToMarketItem[itemId].seller = payable(msg.sender);
        idToMarketItem[itemId].owner = payable(address(0));
        idToMarketItem[itemId].price = price;
        idToMarketItem[itemId].sold = false; 
    }

    function unListToken(address nftContract, uint256 itemId) public payable nonReentrant{
        bool sold = idToMarketItem[itemId].sold;
        address _owner = idToMarketItem[itemId].owner;

        require(sold == false && _owner == address(0), "Item must be on sale");

        uint tokenId = idToMarketItem[itemId].tokenId;

        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        idToMarketItem[itemId].owner = payable(msg.sender);
        idToMarketItem[itemId].seller = payable(address(0));
        idToMarketItem[itemId].sold = true;
    }

    function updatePrice(uint256 itemId, uint256 price) public payable nonReentrant{
         
        bool sold = idToMarketItem[itemId].sold;
        address _owner = idToMarketItem[itemId].owner;

        require(sold == false && _owner == address(0), "Item must be on sale");
        require(price > 0, "Price must be at least 1 wei");

        idToMarketItem[itemId].price = price;
         
    }

    function fetchOwnerOfToken(address nftContract, uint256 tokenId) public view returns(address){

        return IERC721(nftContract).ownerOf(tokenId);

    }


    function createMarketSale(
        address nftContract,
        uint256 itemId,
        address creator_address,
        address owner_address,
        uint256 fee_percentage
    ) public payable nonReentrant {
        uint price = idToMarketItem[itemId].price;
        uint tokenId = idToMarketItem[itemId].tokenId;

        require(msg.value == price + listingPrice, "Please submit the asking price in order to complete the purchase");
        payable(owner).transfer(listingPrice);
    

    
        if(owner_address != creator_address){
            payable(creator_address).transfer(price * fee_percentage / 100);
        }
        else{
            fee_percentage = 0;
        }

        idToMarketItem[itemId].seller.transfer(price * (100 - fee_percentage) / 100);

    
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        idToMarketItem[itemId].owner = payable(msg.sender);
        idToMarketItem[itemId].seller = payable(address(0));
        idToMarketItem[itemId].sold = true;
        _itemsSold.increment();
        
    }


    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        
        for(uint i = 0; i < totalItemCount; i++){
            if(idToMarketItem[i + 1].owner == address(0) && idToMarketItem[i + 1].sold == false){                
                itemCount++;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);

        for(uint i = 0; i < totalItemCount; i++){
            if(idToMarketItem[i + 1].owner == address(0) && idToMarketItem[i + 1].sold == false){
                uint currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex++;
            }
        }

        return items;

    }

    function fetchUserNftsOwner(address userAddress) public view returns (MarketItem[] memory) {
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        
        for(uint i = 0; i < totalItemCount; i++){
            if(idToMarketItem[i + 1].owner == userAddress && idToMarketItem[i + 1].seller == address(0)){                
                itemCount++;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);

        for(uint i = 0; i < totalItemCount; i++){
            if(idToMarketItem[i + 1].owner == userAddress && idToMarketItem[i + 1].seller == address(0)){
                uint currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex++;
            }
        }

        return items;

    }

    function fetchUserNftsSeller(address userAddress) public view returns (MarketItem[] memory) {
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        
        for(uint i = 0; i < totalItemCount; i++){
            if(idToMarketItem[i + 1].seller == userAddress && idToMarketItem[i + 1].owner == address(0)){                
                itemCount++;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);

        for(uint i = 0; i < totalItemCount; i++){
            if(idToMarketItem[i + 1].seller == userAddress  && idToMarketItem[i + 1].owner == address(0)){
                uint currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex++;
            }
        }

        return items;

    }

    function isTokenOnSale(uint256 nftTokenId) public view returns(uint){

        uint totalItemCount = _itemIds.current();        


        for(uint i = 0; i < totalItemCount; i++){
            if(idToMarketItem[i + 1].tokenId == nftTokenId && idToMarketItem[i + 1].sold == false){                
                return idToMarketItem[i+1].price;
            }
        }

        return 0;

    }

    function fetchMarketItemWithTokenId(uint256 tokenId) public view returns(MarketItem memory){
        uint totalItemCount = _itemIds.current();        


        for(uint i = 0; i < totalItemCount; i++){
            if(idToMarketItem[i + 1].tokenId == tokenId){                
                return idToMarketItem[i+1];
            }
        }

        return idToMarketItem[0];


    }
}