// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; // security for non-reentrant
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract FabweltMarketplace is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    Counters.Counter private _itemIds; // Id for each individual item
    Counters.Counter private _itemsSold; // Number of items sold
   
    constructor(){
 
    }


    event Sold(address sender, uint256 soldPrice);


    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    struct MarketItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address payable creator;
        address payable owner;
        address payable seller;
        uint256 soldOn;
        uint256 price;
        uint256 cType;
        bool isSold;
    }


    mapping(uint256 => MarketItem) private idToMarketItem;
 
    // Event is an inhertable contract that can be used to emit events
    event MarketItemCreated(
        uint256 indexed itemId,
        uint256 indexed tokenId,
        address creator,
        address owner,
        address seller,
        uint256 price,
        uint256 soldOn,
        uint256 cType,
        bool isSold
    );

   function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        uint256 cType
    ) public  nonReentrant {
        require(price > 0, "No item for free here");

        uint256 soldOn=price;
        uint256 newPrice=price;
      
        _itemIds.increment();
        uint256 itemId = _itemIds.current();
        idToMarketItem[itemId] = MarketItem(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)), // No owner for the item
            payable(msg.sender),
            newPrice,
            soldOn,
            cType,
            false
        );
        if(cType==721){
             IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
        }else{
        
             IERC1155(nftContract).safeTransferFrom(msg.sender,address(this),tokenId, IERC1155(nftContract).balanceOf(msg.sender, tokenId), "0x0");

        }
        
        emit MarketItemCreated(
            itemId,
            tokenId,
            msg.sender,
            address(0),
            msg.sender,
            newPrice,
            soldOn,
            cType,
            false
        );
    }

    function swapNft(address nftContract,uint256 itemOne,uint256 itemTwo, address seller1, address seller2) public nonReentrant{

        require(idToMarketItem[itemOne].seller == seller1, "Owner of First NFT is changed.");

        require(idToMarketItem[itemTwo].seller == seller2, "Owner of Second NFT is changed.");

        require(
            idToMarketItem[itemOne].isSold == false,
            "Sorry First NFT is already sold"
        );

        require(
            idToMarketItem[itemTwo].isSold == false,
            "Sorry Second NFT is already sold"
        );


        uint256 tokenOne= idToMarketItem[itemOne].tokenId;
        uint256 tokentwo=  idToMarketItem[itemTwo].tokenId;
        idToMarketItem[itemOne].isSold = true;
       
        idToMarketItem[itemOne].seller = payable(seller2);
        idToMarketItem[itemOne].owner =  payable(seller2);
        idToMarketItem[itemOne].isSold = true;
        IERC721(nftContract).transferFrom(address(this),address(seller2),tokenOne);
        _itemsSold.increment();
        idToMarketItem[itemTwo].isSold = true;
        idToMarketItem[itemTwo].seller = payable(seller1);
        idToMarketItem[itemTwo].owner =  payable(seller1);
        idToMarketItem[itemTwo].isSold = true;
        
        IERC721(nftContract).transferFrom(address(this),address(seller1),tokentwo);
        _itemsSold.increment();

    }

    function sellNFT(address nftContract,uint256 itemId, uint256 price) public  {
        require(idToMarketItem[itemId].owner == msg.sender, "Only item owner can perform this operation");
        idToMarketItem[itemId].isSold = false;
        idToMarketItem[itemId].soldOn = price;
        idToMarketItem[itemId].price = price;
        idToMarketItem[itemId].seller = payable(msg.sender);
        idToMarketItem[itemId].owner = payable(address(this));
        uint256 tokenId= idToMarketItem[itemId].tokenId;
        _itemsSold.decrement();
        IERC721(nftContract).transferFrom(msg.sender,address(this) , tokenId);

    }

    function getItemDetails(uint256 itemId) public view returns (MarketItem memory) {
         MarketItem storage currentItem = idToMarketItem[itemId];
         return currentItem;
    }



    function buyNFT(address token, address nftContract, uint256 itemId,uint256 numberOfTokens,uint256 _tokenamount)
        public
        payable
        nonReentrant
    {
       require(
            idToMarketItem[itemId].isSold == false,
            "Sorry NFT is already sold"
        );

        IERC20(token).transferFrom(msg.sender, address(this), _tokenamount);
      
        uint256 tokenId = idToMarketItem[itemId].tokenId;

        uint256 cType = idToMarketItem[itemId].cType;

        if(cType==721){
                IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
                idToMarketItem[itemId].soldOn = _tokenamount;
                idToMarketItem[itemId].isSold = true;
                idToMarketItem[itemId].owner = payable(msg.sender);
                idToMarketItem[itemId].seller = payable(msg.sender);
                _itemsSold.increment();
                 emit Sold(msg.sender,_tokenamount);
        }else{
            require(
                IERC1155(nftContract).balanceOf(address(this), tokenId) >= numberOfTokens,
                "Too much tokens request"
             );
             IERC1155(nftContract).safeTransferFrom(address(this),  msg.sender,tokenId, numberOfTokens, "0x0");
            
            emit Sold(msg.sender,numberOfTokens);

           
       }

           
    }



  function getMarketItems() public view returns (MarketItem[] memory) {
      uint256 itemCount = _itemIds.current();
      uint256 unsoldItemCount = _itemIds.current() - _itemsSold.current();
      uint256 currentIndex = 0;

      MarketItem[] memory items = new MarketItem[](unsoldItemCount);
      for (uint256 i = 0; i < itemCount; i++) {
        if (idToMarketItem[i + 1].owner == address(0)) {
          uint256 currentId = i + 1;
          MarketItem storage currentItem = idToMarketItem[currentId];
          if(currentItem.isSold==false){
            items[currentIndex] = currentItem;
            currentIndex += 1;
          }
        
        }
       }
      return items;
    }

    function fetchPurchasedNFTs() public view returns (MarketItem[] memory) {
          uint256 totalItemCount = _itemIds.current();
          uint256 itemCount = 0;
          uint256 currentIndex = 0;

          for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
              itemCount += 1;
            }
          }

          MarketItem[] memory items = new MarketItem[](itemCount);
          for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
              uint256 currentId = i + 1;
              MarketItem storage currentItem = idToMarketItem[currentId];
              items[currentIndex] = currentItem;
              currentIndex += 1;
            }
          }
          return items;
    }



    function fetchCreatedNFTs() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _itemIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].creator == msg.sender) {
                itemCount += 1; // No dynamic length. Predefined length has to be made
            }
        }

        MarketItem[] memory marketItems = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].creator == msg.sender) {
                uint256 currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                marketItems[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return marketItems;
    }

    function getTokenBalance(address token) public view returns (uint256) {
            return IERC20(token).balanceOf(address(this));
    }


    function withdrawTokens(address token,uint256 _tokenamount) public onlyOwner {
      
       require(IERC20(token).balanceOf(address(this)) >= _tokenamount, "Insufficient funds");

       IERC20(token).approve(address(this), _tokenamount);
       
       IERC20(token).transferFrom(address(this),payable(msg.sender), _tokenamount);
       
    }

 
}