// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; 
import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; 
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; 
import "hardhat/console.sol";

 

 interface ICardNFT
{

 
 
 
    function getOpenBoxFee () external view returns(uint256);
   
}

contract NftCardMarket is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds; 
    Counters.Counter private _itemsSold;
 
    address payable owner;
    ICardNFT _cardNftContract; 

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        // Underscore is a special character only used inside
        // a function modifier and it tells Solidity to
        // execute the rest of the code.
        _;
    }

    mapping (address => bool) public whiteList;
 
 
    address public  _feeAddress;//手续费的收取地址
    address public _token;

    uint256 public constant MAX_SUPPLY = 5162;
 

    constructor(address feeAddress,address token,ICardNFT cardNftContract) {
        owner = payable(msg.sender);
        _feeAddress=feeAddress;
        _token=token;
        _cardNftContract=cardNftContract;
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
        bool isDel;
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
 
    
     function getMarkFee() public  view returns(uint256)
     {
        return _cardNftContract.getOpenBoxFee();
     }

    function getMarkFeeAddress() public  view returns(address){
        return _feeAddress;
    }
 
    function setMarketItemPrice(uint256 itemId,uint256 price) public  
    {
        require(owner==msg.sender);
        idToMarketItem[itemId] .price=price;
    }
 
    function getTokenAddress() public view returns(address)
    {
        return _token;
    }

    function setMarkFeeAddress(address val) public onlyOwner{
          _feeAddress=val;
    }

    function setTokenAddress(address val) public  onlyOwner{
          _token=val;
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
        console.log(itemId);
        idToMarketItem[itemId] =  MarketItem(
            itemId,
            nftContract,
            tokenId,
            payable(sender),
            payable(address(0)),
            price,
            false,
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
        uint256 fee=getMarkFee();
        //  console.log('getTokenFee1',price);
        // uint256 f=price*fee/100;
        // console.log('getTokenFee2',f);
        return fee;
    }
    
    function removeMarketItem(
        address nftContract,
        uint256 itemId
        ) public  nonReentrant {

        uint tokenId = idToMarketItem[itemId].tokenId;
  
        require(idToMarketItem[itemId].seller ==msg.sender,'is not owner');
        require(idToMarketItem[itemId].sold ==false,'is not remove');
        IERC721(nftContract).transferFrom(address(this),msg.sender,tokenId);
      
        idToMarketItem[itemId].isDel=true;
 

         
    }

    // 创建销售市场项目转让所有权和资金
    function createMarketSale(
        address nftContract,
        uint256 itemId
        ) public payable nonReentrant {
   
        uint price = idToMarketItem[itemId].price;
        uint tokenId = idToMarketItem[itemId].tokenId;
        uint256 fee=getTokenFee(price);
        address feeAddress=getMarkFeeAddress();
        address tokenAddress=getTokenAddress();
        IERC20 token=IERC20(tokenAddress);
        uint256 total=fee+price;

 
        //购买者余额要大于商品的价格
        require(token.balanceOf(msg.sender)>= total, "Please submit the asking price in order to complete the purchase"); // 如果要价不满足会不会产生误差
       
        //验证是否授权
        require(token.allowance(msg.sender,address(this))>=total,'Insufficient authorized balance For TTC');

        require(fee>0,'fee set failed') ;       
        require(token.transferFrom(msg.sender,feeAddress,fee),'TTC transfer fee failed') ;
        require(token.transferFrom(msg.sender,idToMarketItem[itemId].seller,price),'TTC transfer price failed') ;
        
        IERC721(nftContract).transferFrom(address(this),msg.sender,tokenId);

        idToMarketItem[itemId].owner = payable(msg.sender);
        idToMarketItem[itemId].sold = true;
        _itemsSold.increment();
         
    }
    // 返回市场上所有未售出的商品
    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0;
        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].sold == false && idToMarketItem[i + 1].isDel==false)  {
                itemCount += 1;
            }
        }
 
        MarketItem[] memory items = new MarketItem[](itemCount); // 如果地址为空(未出售的项目)，将填充数组   
        uint currentIndex = 0;
        {
            for (uint i = 0; i < totalItemCount; i++) {
                uint currentId =  i + 1;
                if (idToMarketItem[currentId].sold == false && idToMarketItem[currentId].isDel==false) {                 
                    MarketItem memory currentItem = idToMarketItem[currentId]; 
                    items[currentIndex] = currentItem;    
                    currentIndex+=1;         
                } 
            }
        }


        return items;
    }
    // 获取用户购买的NFT
    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        uint totalItemCount = _itemIds.current();
     
        uint itemCount = 0; 
        for (uint i = 0; i < totalItemCount; i++) {
             if (idToMarketItem[i + 1].owner == msg.sender && idToMarketItem[i + 1].isDel==false)  {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        uint currentIndex = 0;
        for (uint256 i = 0; i < totalItemCount; i++) {
            uint currentId =  i + 1;
 
            if (idToMarketItem[currentId].owner == msg.sender && idToMarketItem[currentId].isDel==false) {
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;            
                currentIndex+=1;
            }

 

        }
        return items;
    }
    // 获取卖家制作的NFT
    function fetchItemsCreated() public view returns (MarketItem[] memory) {
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0; 
        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender && idToMarketItem[i + 1].isDel==false)  {
                itemCount += 1;
            }
        }
        MarketItem[] memory items = new MarketItem[](itemCount); 
        uint currentIndex = 0;
        for (uint i = 0; i < totalItemCount; i++) {
            uint currentId = i + 1;
            if (idToMarketItem[currentId].seller == msg.sender && idToMarketItem[currentId].isDel==false) {         
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;     
                currentIndex+=1;   
            }
        }
        return items;
    }
}