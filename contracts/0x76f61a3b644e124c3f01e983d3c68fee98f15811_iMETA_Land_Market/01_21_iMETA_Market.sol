//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";




contract iMETA_Land_Market is Initializable, UUPSUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable {    
    using SafeMathUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;
  	mapping (address => uint) ownersaleCount;			

    //log message (when Item is sold)
    event MarketItemCreated_eth ( uint indexed marketId, address indexed nftContract, uint256 indexed tokenId, address  seller, address  owner, uint256 eth_price, uint256 price, bool sold);
    event MarketItemCreated_token ( uint indexed marketId, address indexed nftContract, uint256 indexed tokenId, address  seller, address  owner, uint256 eth_price, uint256 price, bool sold);
    event event_withdraw_eth (address indexed owner, uint indexed reward_coin);
    event event_withdraw_token(address indexed owner, uint indexed reward_token);
    event event_receive_user_eth (uint indexed reward_coin, address indexed owner);
    event event_receive_user_token(uint indexed reward_token, address indexed owner);
    event event_buy_eth( uint _marketId, address owner,uint coin_price, uint token_price, bool sold);
    event event_buy_token( uint _marketId, address owner,uint coin_price, uint token_price, bool sold);
    
    CountersUpgradeable.Counter private _marketIds; //total number of items ever created
    CountersUpgradeable.Counter private _itemsSold; //total number of items sold
    uint256 public marketlist; //total number of items sold

    struct MarketItem {
        uint marketId;
        address nftContract;
        uint256 tokenId;
        address payable seller; //person selling the nft
        address payable owner; //owner of the nft
        uint256 eth_price;
        uint256 price;
        bool sold;
    }
    
    IERC20Upgradeable public _token;

    ///@dev initialize
    function initialize(IERC20Upgradeable token) public initializer {
        _token = token;
        _transferOwnership(_msgSender());
        set_marketlist(30);
    }
    
    function set_marketlist(uint list) public {
        marketlist = list;
    }

    //a way to access values of the MarketItem struct above by passing an integer ID
    mapping(uint256 => MarketItem) public idMarketItem;
    uint256[] internal marketList;

    
    function _authorizeUpgrade(address) internal override {}
    
    ///@dev Check Contract Ether
    function Balanceof_eth() public view returns (uint256) {
        return address(this).balance;
    }

    ///@dev Check Contract iMETA token
    function Balanceof_toekn(address _tokenContract) public view returns (uint256) {
         IERC20Upgradeable tokenContract = IERC20Upgradeable(_tokenContract);
        return tokenContract.balanceOf(address(this));
    }    

    ///@dev Wirhdraw Contract Ether
    function withdraw_eth(uint256 _amount) external payable onlyOwner() {
        require(address(this).balance >= _amount,"Not enough balance");
        payable(owner()).transfer(_amount);
        emit event_withdraw_eth(msg.sender, _amount);
    }
	
    ///@dev Wirhdraw Contract iMETA token
    function withdraw_token(address _tokenContract, uint256 _amount) external onlyOwner{
        IERC20Upgradeable tokenContract = IERC20Upgradeable(_tokenContract);
        require(tokenContract.balanceOf(address(this)) >= _amount,"Not enough token");
        tokenContract.transfer(msg.sender, _amount);
        emit event_withdraw_token(msg.sender, _amount);
    }

    ///@notice function to create market item with Ether
    function createMarketItem_eth(address _nftContract, uint256 _tokenId, uint256 _eth_price) public payable nonReentrant{

        require(_eth_price > 0, "Price must be above zero");
        _marketIds.increment(); //add 1 to the total number of items ever created
        uint256 marketId = _marketIds.current();
        idMarketItem[_tokenId] = MarketItem(marketId, _nftContract, _tokenId, payable(msg.sender), payable(address(this)), _eth_price,0, false);
        IERC721Upgradeable(_nftContract).transferFrom(msg.sender, address(this), _tokenId);
        marketList.push(_tokenId);
        ownersaleCount[msg.sender] += 1;
        emit MarketItemCreated_eth(marketId, _nftContract, _tokenId, msg.sender, msg.sender, _eth_price, 0, false);
        
    }

    ///@notice function to create market item with iMETA token
    function createMarketItem_token(address _nftContract, uint256 _tokenId, uint256 _price) public nonReentrant{
        require(_price > 0, "Price must be above zero");
        _marketIds.increment(); //add 1 to the total number of items ever created
        uint256 marketId = _marketIds.current();
        idMarketItem[_tokenId] = MarketItem(marketId, _nftContract, _tokenId, payable(msg.sender), payable(address(this)), 0, _price, false);
        IERC721Upgradeable(_nftContract).transferFrom(msg.sender, address(this), _tokenId);
        marketList.push(_tokenId);
        ownersaleCount[msg.sender] += 1;
        emit MarketItemCreated_token(marketId, _nftContract, _tokenId, msg.sender, msg.sender, 0, _price, false);
    }

    /// @notice function to create a sale with Ether
    function buy_with_eth(address _nftContract, uint256 _tokenId, uint256 _eth_price) public payable nonReentrant{
        
        uint price = idMarketItem[_tokenId].eth_price;
        require(msg.value == price, "Please submit the asking price in order to complete purchase");
        require(_eth_price == price, "Please submit the asking price in order to complete purchase");
        IERC721Upgradeable(_nftContract).transferFrom(address(this), msg.sender, _tokenId);

        uint256 test_token_price = _eth_price.mul(95).div(100);
        payable(idMarketItem[_tokenId].seller).transfer(test_token_price);
        
        uint keyListIndex = idMarketItem[_tokenId].marketId - 1;
        uint keyListLastIndex = marketList.length - 1;
        idMarketItem[marketList[keyListLastIndex]].marketId = keyListIndex + 1;
        marketList[keyListIndex] = marketList[keyListLastIndex];
        marketList.pop();
        _marketIds.decrement();
        ownersaleCount[idMarketItem[_tokenId].seller] -= 1;
        delete idMarketItem[_tokenId];
        emit event_buy_eth(_tokenId, msg.sender, 0, test_token_price, false);
    }
    /// @notice function to create a sale with iMETA token
    function buy_with_token(address _nftContract, uint256 _tokenId, uint256 _price) public nonReentrant{
        uint price = idMarketItem[_tokenId].price;
        require(_price == price, "Please submit the asking price in order to complete purchase");
        IERC721Upgradeable(_nftContract).transferFrom(address(this), msg.sender, _tokenId);

        _token.transferFrom(msg.sender, address(this), price);
        uint256 test_token_price = _price.mul(95).div(100);
        _token.transfer(idMarketItem[_tokenId].seller, test_token_price);

        uint keyListIndex = idMarketItem[_tokenId].marketId - 1;
        uint keyListLastIndex = marketList.length - 1;
        idMarketItem[marketList[keyListLastIndex]].marketId = keyListIndex + 1;
        marketList[keyListIndex] = marketList[keyListLastIndex];
        marketList.pop();
        _marketIds.decrement();
        ownersaleCount[idMarketItem[_tokenId].seller] -= 1;
        delete idMarketItem[_tokenId];
        emit event_buy_token(_tokenId, msg.sender, test_token_price, 0, false);
		
    }
    
    /// @notice function to Cancellation of Sale
    function cancleMarketSale(address _nftContract, uint256 _tokenId) public nonReentrant{
        require(idMarketItem[_tokenId].seller == msg.sender, "It's Not Seller");
        IERC721Upgradeable(_nftContract).transferFrom(address(this), msg.sender, _tokenId);
        
        uint keyListIndex = idMarketItem[_tokenId].marketId - 1;
        uint keyListLastIndex = marketList.length - 1;
        idMarketItem[marketList[keyListLastIndex]].marketId = keyListIndex + 1;
        marketList[keyListIndex] = marketList[keyListLastIndex];
        marketList.pop();
        _marketIds.decrement();
        ownersaleCount[msg.sender] -= 1;
        delete idMarketItem[_tokenId];
    }
    
    /// @notice function to Change Ether price
    function change_Price_eth(uint256 _tokenId, uint256 _price) public payable nonReentrant{
        require(idMarketItem[_tokenId].seller == msg.sender, "It's Not Seller");
        idMarketItem[_tokenId].eth_price = _price;
    }

    /// @notice function to Change iMETA token price
    function change_Price_token(uint256 _tokenId, uint256 _price) public payable nonReentrant{
        require(idMarketItem[_tokenId].seller == msg.sender, "It's Not Seller");
        idMarketItem[_tokenId].price = _price;
    }
    
    function fetchMarketItems(uint256 count) public view returns (MarketItem[] memory){
        require(count == 0, "It's Not Seller");
        MarketItem[] memory items =  new MarketItem[](marketList.length);
        for(uint i = 0; i < marketList.length; i++){
            items[i] = idMarketItem[marketList[i]];
        }
        return items; 
    }

    
    function fetchMyMarketItems(uint256 count) public view returns (MarketItem[] memory){
        require(count == 0, "It's Not Seller");
        uint currentIndex = 0;
        MarketItem[] memory items =  new MarketItem[](ownersaleCount[msg.sender]);
        for(uint i = 0; i < marketList.length; i++){
            if(idMarketItem[marketList[i]].seller == msg.sender){
                items[currentIndex] = idMarketItem[marketList[i]];
                currentIndex += 1;
            }
        }
        return items; 
    }

    function veiw_marketListSize() public view returns(uint){
        return marketList.length;
    }

    function veiw_markeList() public view returns(uint[] memory){
        return marketList;
    }
    
    function fetchMarketItemspage(uint count) public view returns (MarketItem[] memory){
        MarketItem[] memory items =  new MarketItem[](count);
        for(uint i = 0; i < count; i++){
            items[i] = idMarketItem[marketList[i]];
        }
        return items; 
    }

    function InfoMarketItem(uint256 _tokenId) public view returns (MarketItem memory){
        require(idMarketItem[_tokenId].marketId > 0, "It's Not Registered");
        return idMarketItem[_tokenId];
    }
}