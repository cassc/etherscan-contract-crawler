// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol"; // in the upgradable contracts we need to remove constructor and replace that with Initializer
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract AstroBirdMarketplace is Initializable, UUPSUpgradeable, ReentrancyGuardUpgradeable,OwnableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private itemIds;
    CountersUpgradeable.Counter private _itemsSold;
    uint public itemId;
     address public AstroToken;
     
    function initialize(address _astroTokenAddress)public virtual initializer{
__ReentrancyGuard_init();
__Ownable_init();
__UUPSUpgradeable_init();
AstroToken = _astroTokenAddress;
    }
    function _authorizeUpgrade(address _newImplementation) internal override onlyOwner {}
     struct MarketItem {
         uint itemId;
         address nftContract;
         uint256 tokenId;
         address payable seller;
         address payable owner;
         uint256 price;
         bool inToken;
         bool sold;
     }
     
     mapping(uint256 => MarketItem) public idToMarketItem;
     mapping(address => mapping(uint256 =>MarketItem)) public tokenIdtoMarketItem;
     
     event MarketItemCreated (
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
     );
     event MarketItemDeleted (
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner

     );
     
     event MarketItemSold (
         uint indexed itemId,
         address owner
         );
     
    
    
    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
        ) public virtual payable nonReentrant {
            require(price > 0, "Price must be greater than 0");
            itemIds.increment();
             itemId = itemIds.current();
  
             tokenIdtoMarketItem[nftContract][tokenId] =  MarketItem(
                itemId,
                nftContract,
                tokenId,
                payable(msg.sender),
                payable(address(0)),
                price,
                false,
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

function getMarketItem(address nftContract, uint256 tokenId)public view returns(MarketItem memory){
return tokenIdtoMarketItem[nftContract][tokenId];
}
 function createMarketItemWithERC20(
        address nftContract,
        uint256 tokenId,
        uint256 price
        ) public virtual payable nonReentrant {
            require(price > 0, "Price must be greater than 0");
            itemIds.increment();
             itemId = itemIds.current();
  tokenIdtoMarketItem[nftContract][tokenId]=MarketItem(
                itemId,
                nftContract,
                tokenId,
                payable(msg.sender),
                payable(address(0)),
                price,
                true,
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
        
    function createMarketSale(
        address nftContract,
        uint256 tokenId
        ) public virtual payable nonReentrant {
            uint price =  tokenIdtoMarketItem[nftContract][tokenId].price;
            uint tokenId =  tokenIdtoMarketItem[nftContract][tokenId].tokenId;
            bool sold =  tokenIdtoMarketItem[nftContract][tokenId].sold;
            bool inToken =  tokenIdtoMarketItem[nftContract][tokenId].inToken;
            uint priceTax = price *1/100;
            require(inToken != true, "This Sale is in Token Sale");

            require(msg.value == price + priceTax, "Please submit the asking price in order to complete the purchase");
            require(sold != true, "This Sale has alredy finnished");
            emit MarketItemSold(
                itemId,
                msg.sender
                );

             tokenIdtoMarketItem[nftContract][tokenId].seller.transfer(msg.value);
            IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
             tokenIdtoMarketItem[nftContract][tokenId].owner = payable(msg.sender);
            _itemsSold.increment();
             tokenIdtoMarketItem[nftContract][tokenId].sold = true;
        }
        
   
     function createMarketSaleWithERC20(
        address nftContract,
        uint256 tokenId
        ) public virtual payable nonReentrant {
            uint price =  tokenIdtoMarketItem[nftContract][tokenId].price;
            uint tokenId =  tokenIdtoMarketItem[nftContract][tokenId].tokenId;
            bool sold =  tokenIdtoMarketItem[nftContract][tokenId].sold;
            bool inToken =  tokenIdtoMarketItem[nftContract][tokenId].inToken;
            uint priceTax = price *1/100;
            require(sold != true, "This Sale has alredy finnished");
            require(inToken = true, "This Sale has not in Token");
            emit MarketItemSold(
                itemId,
                msg.sender
                );

           IERC20(AstroToken).transferFrom(msg.sender, tokenIdtoMarketItem[nftContract][tokenId].seller,price);
           IERC20(AstroToken).transferFrom(msg.sender,address(this),priceTax);
            IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
             tokenIdtoMarketItem[nftContract][tokenId].owner = payable(msg.sender);
            _itemsSold.increment();
             tokenIdtoMarketItem[nftContract][tokenId].sold = true;
        }
        
        function createCancelSale(address nftContract,uint256 tokenId)public virtual{
            require(msg.sender == tokenIdtoMarketItem[nftContract][tokenId].seller,"NOT SELLER OF THE NFT");
            require(! tokenIdtoMarketItem[nftContract][tokenId].sold,"NFT ALREADY SOLD!");
            IERC721(nftContract).transferFrom(address(this),msg.sender,  tokenIdtoMarketItem[nftContract][tokenId].tokenId);
                
            emit MarketItemDeleted(
                itemId,
                nftContract,
                 tokenIdtoMarketItem[nftContract][tokenId].tokenId,
                msg.sender,
                msg.sender
            );
        }

    function fetchMarketItems() public virtual view returns (MarketItem[] memory) {
        uint itemCount = itemIds.current();
        uint unsoldItemCount = itemIds.current() - _itemsSold.current();
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
 function withdraw() public virtual payable onlyOwner {    
    // This will payout the owner 95% of the contract balance.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }   
  function withdrawTokens() public virtual  onlyOwner {    
    // This will payout the owner 95% of the contract balance.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    IERC20(AstroToken).transfer(owner(), IERC20(AstroToken).balanceOf(address(this)));
    // =============================================================================
  }      
}


/// Thanks for inspiration: https://github.com/dabit3/polygon-ethereum-nextjs-marketplace/