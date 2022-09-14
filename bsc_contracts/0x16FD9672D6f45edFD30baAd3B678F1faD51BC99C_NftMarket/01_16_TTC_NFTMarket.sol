// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; 
import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; 
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; 
import "hardhat/console.sol";

interface ICardNFT
{

 
    function getTokenAddress() external view returns(address);
    function getStageAddress() external view returns(address);
    function getMarkFee() external view returns(uint256);
    function getMarkFeeAddress() external  view returns(address);
}

contract NftMarket is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds; 
    Counters.Counter private _itemsSold;
    address payable owner;
 
    uint256 public  _fee=5;//扣除手续费的额度
    
    address public  _feeAddress;//手续费的收取地址

    ICardNFT CardNftContract; 

    constructor(ICardNFT card) {
        owner = payable(msg.sender);
        CardNftContract=card;
    }
    // 定义 NFT 销售属性
    struct MarketItem {
        uint itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }
    mapping(uint256 => MarketItem) public idToMarketItem;
    // 市场项目创建触发器
    event MarketItemCreated (
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );
 
    
     function setCardNftContract(ICardNFT card) public  
    {
        require(owner==msg.sender);
        CardNftContract=card;
    }
 
    function setMarketItemPrice(uint256 itemId,uint256 price) public  
    {
        require(owner==msg.sender);
        idToMarketItem[itemId] .price=price;
    }

    function autoCreateMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        address sender
    ) public  {
         
        require(CardNftContract.getStageAddress()==msg.sender,'autoCreateMarketItem error');
        require(msg.sender!=address(0),'seller address error');
   
 
        _itemIds.increment();
        uint256 itemId = _itemIds.current();
 
        idToMarketItem[itemId] =  MarketItem(
            itemId,
            nftContract,
            tokenId,
            payable(sender),
            payable(address(0)),
            price,
            false
        );

        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            sender,
            address(0),
            price,
            false
        );
    }
      

    // 在市场上销售一个NFT
    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
   
    ) public payable nonReentrant {
         
        require(msg.sender!=address(0),'seller address error');
        address sender=msg.sender;
 
        _itemIds.increment();
        uint256 itemId = _itemIds.current();
 
        idToMarketItem[itemId] =  MarketItem(
            itemId,
            nftContract,
            tokenId,
            payable(sender),
            payable(address(0)),
            price,
            false
        );

        require( IERC721(nftContract).isApprovedForAll(sender, address(this) ),'No authorized market contract');
        IERC721(nftContract).transferFrom(sender, address(this), tokenId); // 将NFT的所有权转让给合同
        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            sender,
            address(0),
            price,
            false
        );
    }


    function getTokenFee(uint256 price) private view returns(uint256)
    {
        uint256 fee=CardNftContract.getMarkFee();
         console.log('getTokenFee1',price);
        uint256 f=price*fee/100;
        console.log('getTokenFee2',f);
        return f;
    }
    
    // 创建销售市场项目转让所有权和资金
    function createMarketSale(
        address nftContract,
        uint256 itemId
        ) public payable nonReentrant {
   
        uint price = idToMarketItem[itemId].price;
        uint tokenId = idToMarketItem[itemId].tokenId;
        uint256 fee=getTokenFee(price);
        address feeAddress=CardNftContract.getMarkFeeAddress();
        address tokenAddress=CardNftContract.getTokenAddress();
        IERC20 token=IERC20(tokenAddress);
        uint256 total=fee+price;

 
        //购买者余额要大于商品的价格
        require(token.balanceOf(msg.sender)>= total, "Please submit the asking price in order to complete the purchase"); // 如果要价不满足会不会产生误差
       
        //验证是否授权
        require(token.allowance(msg.sender,address(this))>=total,'Insufficient authorized balance For TTC');

        require(fee>0,'fee set failed') ;       
        require(token.transferFrom(msg.sender,idToMarketItem[itemId].seller,fee),'TTC transfer fee failed') ;
        require(token.transferFrom(msg.sender,idToMarketItem[itemId].seller,price),'TTC transfer price failed') ;
        
        IERC721(nftContract).transferFrom(address(this),msg.sender,tokenId);

        idToMarketItem[itemId].owner = payable(msg.sender);
        idToMarketItem[itemId].sold = true;
        _itemsSold.increment();
         
    }
    // 返回市场上所有未售出的商品
    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint itemCount = _itemIds.current();
        uint unsoldItemCount = _itemIds.current() - _itemsSold.current(); // 更新数量
        uint currentIndex = 0;
        MarketItem[] memory items = new MarketItem[](unsoldItemCount); // 如果地址为空(未出售的项目)，将填充数组
        for (uint i = 0; i < itemCount; i++) {
            if (idToMarketItem[i + 1].owner == address(0)) {  
                uint currentId =  i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId]; 
                items[currentIndex] = currentItem;
                currentIndex += 1;
            } 
        }
        return items;
    }
    // 获取用户购买的NFT
    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;
        for (uint i = 0; i < totalItemCount; i++) {
            for (uint j = 0; j < totalItemCount; j++) {
                itemCount += 1;
            }
        }
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                uint currentId =  i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
    // 获取卖家制作的NFT
    function fetchItemsCreated() public view returns (MarketItem[] memory) {
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;
        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                itemCount += 1;
            }
        }
        MarketItem[] memory items = new MarketItem[](itemCount); 
        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                uint currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
}