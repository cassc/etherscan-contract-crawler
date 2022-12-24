// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract Braands is Initializable, ERC1155Upgradeable, OwnableUpgradeable{
 receive() external payable {}
    fallback() external payable {}

    
  string public name;
  string public symbol;
  address payable collector;
  uint Platfrom_fees;
  using Counters for Counters.Counter;
  Counters.Counter public itemIds;
  Counters.Counter public auctionIds;
  Counters.Counter public tokenIds;
  uint public brandsLenght;
  uint public lastendAuction;
  bool private initialized;
  uint public Auction_fee;
  
  struct MarketItem {
      uint itemId;
      uint256 tokenId;
      uint units;
      uint units_left;
      address payable seller;
      uint256 totalprice;
      uint PricePerUnit;
      uint current_item_price;
      uint time;
    }
    event MarketItemCreated (
      uint indexed itemId,
      uint256 tokenId,
      uint units,
      uint units_left,
      address seller,
      uint256 totalprice,
      uint PricePerUnit,
      uint current_item_price,
      uint time
    );
    event AuctionItemCreated (
      uint indexed auctionId,
      uint256 tokenId,
     // uint units,
      address seller,
      uint256 staringbid,
     // uint PricePerUnit,
      uint startedtime,
      uint endtime,
      uint hightestbid,
      //bool buynow,
      uint buynowAmount,
      address payable hightestbidderAddress
    );
     struct AuctionItem {
      uint auctionId;
      uint256 tokenId;
     // uint units;
      address payable seller;
      uint256 staringbid;
     // uint PricePerUnit;
      uint startedtime;
      uint endtime;
      uint hightestbid;
      //bool buynow;
      uint buynowAmount;
      address payable hightestbidderAddress;
    }

    

  mapping(uint => string) public tokenURI;
  mapping (uint => address) public Minter_address;
  mapping(uint=> uint) public max_supply;
  mapping(uint=> uint) public current_supply;
  mapping(uint => uint) public intial_price;
  mapping(uint256 => MarketItem) public idToMarketItem;
  mapping(uint => uint) public Mint_time;
  mapping(uint => uint) public VaildFor;//in years
  mapping (uint =>address[]) public history_a;
  mapping (uint => uint[]) public history_p;
  mapping (uint => uint[]) public history_t;
  mapping (uint => uint[]) public history_amt;
  mapping(uint256 => AuctionItem) public idToAuctionItem;
  mapping (uint => uint[]) public history_Ap;
  mapping (uint => uint[]) public history_At;
  mapping (uint => uint[]) public history_Aamt;
  mapping (uint =>address[]) public history_Aa;
  mapping (uint => bool) public _Buynow;



     function initialize(address _owner,uint _Platfrom_fees,uint _Auction_fee) initializer public {
    __ERC1155_init("");
     __Ownable_init();
    name = "Braands.io";
    symbol = "BRD";
    collector = payable (_owner);
    Platfrom_fees = _Platfrom_fees;
    Auction_fee = _Auction_fee;
    setApprovalForAll(address(this),true);
    require(!initialized, "Contract instance has already been initialized");
    initialized = true;
  }
  function mint(address _to,uint _amount,string memory _uri,uint _intial_price, uint buyVail) external payable {
   tokenIds.increment();
   uint newtokenIds = tokenIds.current();
   require(msg.value == _intial_price,"please put the correct price");
    _mint(_to, newtokenIds, _amount, "");
    _setURI(newtokenIds,_uri);
    payable(collector).transfer(_intial_price);
    max_supply[newtokenIds] = _amount;
    intial_price[newtokenIds]= _intial_price;
    current_supply[newtokenIds] = _amount;
    Mint_time[newtokenIds] = block.timestamp;
    VaildFor[newtokenIds] = buyVail;
    Minter_address[newtokenIds]= msg.sender;
    setApprovalForAll(address(this),true);
    }

  /*function mintBatch(address _to, uint[] memory _ids, uint[] memory _amounts) external  {
    _mintBatch(_to, _ids, _amounts, "");
  }*/

  function burn(uint _id, uint _amount,address _from) external { //only for owner
    //require(balanceOf(msg.sender,_id)>=_amount,"check your balance");
   require(msg.sender == collector,"Don't have power");
   _burn(_from, _id, _amount);
    current_supply[_id] = current_supply[_id]-_amount;
  }

  /*function burnBatch(uint[] memory _ids, uint[] memory _amounts) external {
    _burnBatch(msg.sender, _ids, _amounts);
  }*/

  /*function burnForMint(address _from, uint[] memory _burnIds, uint[] memory _burnAmounts, uint[] memory _mintIds, uint[] memory _mintAmounts) external {
    _burnBatch(_from, _burnIds, _burnAmounts);
    _mintBatch(_from, _mintIds, _mintAmounts, "");
  }*/

  function _setURI(uint _id, string memory _uri) internal {
    tokenURI[_id] = _uri;
    emit URI(_uri, _id);
  }

  function uri(uint _id) public override view returns (string memory) {
    return tokenURI[_id];
  }
  function CheckValidity (uint _id) public view returns (bool){
      uint validityTime =  Mint_time[_id] + (VaildFor[_id]*31536000);
      block.timestamp > validityTime;
      return false;
  }
  function setUrl(uint tokenId, string memory url) public payable {
   require(balanceOf(msg.sender, tokenId)>(max_supply[tokenId])/2,"dont more than 50%");
   tokenURI[tokenId] = url;

  }
 /*-----------------------------------MarketPlace--------------------------------*/
    function updatePlatfrom_fees(uint _Platfrom_fees) public payable {
      require(collector == msg.sender, "Only marketplace owner can update listing price.");
      Platfrom_fees = _Platfrom_fees;
    }
    function getPlatfrom_fees() public view returns (uint256) {
      return Platfrom_fees;
    }
    function updatecollector(address newcollector) public payable {
      require(collector == msg.sender, "Only marketplace owner can update address");
      collector = payable(newcollector);
    }
     function getcollector() public view returns (address) {
      return collector;
    }
    function createIteam(uint _tokenID,uint _pricePerUnit,uint numberOfUnit)payable public {
        itemIds.increment();
        require(balanceOf(msg.sender,_tokenID)>=numberOfUnit,"check your balance");
        uint newitemIds = itemIds.current();
        uint totalAmount = numberOfUnit*_pricePerUnit;
        require(totalAmount>0,"price cannot be Zero");
        uint fee = (Platfrom_fees*totalAmount)/100;
        require (msg.value == fee,"Paying fee not correct" );
        payable(collector).transfer(fee);
        idToMarketItem[newitemIds] =  MarketItem(
        newitemIds,
        _tokenID,
        numberOfUnit,
        numberOfUnit,
        payable(msg.sender),
        totalAmount,
        _pricePerUnit,
        totalAmount,
        block.timestamp

    );
    _safeTransferFrom(msg.sender,address(this),_tokenID,numberOfUnit,"");
    emit MarketItemCreated(
      newitemIds,
      _tokenID,
      numberOfUnit,
      numberOfUnit,
      payable(msg.sender),
      totalAmount,
      _pricePerUnit,
      totalAmount,
      block.timestamp
    );
    

    }
    function saleItem(uint _newitemIds,uint _numberOfUnit) payable public {
        uint leftUnits = idToMarketItem[_newitemIds].units_left;//v
        require(_numberOfUnit<= leftUnits,"Number units for sale are less");//v
       uint priceOfsale = idToMarketItem[_newitemIds].PricePerUnit*_numberOfUnit;//v
        uint feeforsale = (priceOfsale*Platfrom_fees)/100;//v
       require(msg.value == feeforsale+priceOfsale,"the sale does not match");//v
       address seller = idToMarketItem[_newitemIds].seller;//v
       payable(seller).transfer(priceOfsale);
       uint _tokenID = idToMarketItem[_newitemIds].tokenId;//v
       _safeTransferFrom(address(this),msg.sender,_tokenID,_numberOfUnit,"");//v
       idToMarketItem[_newitemIds].units_left = idToMarketItem[_newitemIds].units_left - _numberOfUnit;//v
       idToMarketItem[_newitemIds].current_item_price = idToMarketItem[_newitemIds].current_item_price - priceOfsale;//v
       payable(collector).transfer(feeforsale);
       history_a[_tokenID].push(msg.sender);//history
       history_p[_tokenID].push(priceOfsale);
       history_t[_tokenID].push(block.timestamp);
       history_amt[_tokenID].push(_numberOfUnit);
    }

   function IsItemsoldout(uint itemid) public view returns(bool){
     if (idToMarketItem[itemid].units_left ==0)
     return true;  
     {return false;}
   }
   function calculate_fee(uint _pricePerUnit,uint numberOfUnit) public view returns(uint) {
       uint totalAmount = numberOfUnit*_pricePerUnit;
       uint fee = (Platfrom_fees*totalAmount)/100;
       return fee;
   }
   function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
    function fee_for_sale(uint _newitemIds,uint _numberOfUnit) public view returns(uint) {
        uint leftUnits = idToMarketItem[_newitemIds].units_left;
        require(_numberOfUnit<= leftUnits,"Number units for sale are less");
        uint priceOfsale = idToMarketItem[_newitemIds].PricePerUnit*_numberOfUnit;
        uint feeforsale = (priceOfsale*Platfrom_fees)/100;
        return(feeforsale);
    }
    function get_price(uint _newitemIds,uint _numberOfUnit) public view returns (uint){
        uint priceOfsale = idToMarketItem[_newitemIds].PricePerUnit*_numberOfUnit;
        return(priceOfsale);
    }
    function total_fee_for_sale(uint _newitemIds,uint _numberOfUnit) public view returns(uint){
        uint priceOfsale = idToMarketItem[_newitemIds].PricePerUnit*_numberOfUnit;
        uint feefor_sale = (priceOfsale*Platfrom_fees)/100;
        uint price_Of_sale = idToMarketItem[_newitemIds].PricePerUnit*_numberOfUnit;
        uint total = price_Of_sale+feefor_sale;
        return total;
    }
    function createAuction(uint _tokenID,uint _pricePerUnit,uint numberOfUnit, uint vaild_days,bool buynow,uint buynowAmount)payable public returns(uint){
        auctionIds.increment();
         require(balanceOf(msg.sender,_tokenID)== max_supply[_tokenID],"check your balance");
        uint newauctionIds = auctionIds.current();
        uint totalAmount = numberOfUnit*_pricePerUnit;
        require(totalAmount>0,"price cannot be Zero");
        uint fee = (Platfrom_fees*totalAmount)/100;
        uint auction_fee = Auction_fee ;
        uint starttime = block.timestamp;
        uint endtime = starttime + (vaild_days * 86400);
        _Buynow[newauctionIds] = buynow;
        require (msg.value == fee+auction_fee ,"Paying fee not correct" );
        payable(collector).transfer(msg.value);
        idToAuctionItem[newauctionIds] =  AuctionItem(
            newauctionIds,
            _tokenID,
           // numberOfUnit,
            payable (msg.sender),
            totalAmount,
           // _pricePerUnit,
            starttime,    
            endtime,
            totalAmount,
            //buynow,
            buynowAmount,
           payable  (address(0))

        );
        _safeTransferFrom(msg.sender,address(this),_tokenID,numberOfUnit,"");
    emit  AuctionItemCreated (
       newauctionIds,
        _tokenID,
       // numberOfUnit,
        payable (msg.sender),
        totalAmount,
       // _pricePerUnit,
        starttime,    
        endtime,
        totalAmount,
        //buynow,
        buynowAmount,
        payable (address(0))
    );
    return newauctionIds;
    }
    function bid(uint newauctionIds, uint bidamount) payable public {
        require(idToAuctionItem[newauctionIds].endtime > block.timestamp, "Auction is end");
        require(idToAuctionItem[newauctionIds].hightestbid < bidamount,"the bid should be higher than the previeous bid");
        uint fees = 0.25 ether;
        require(msg.value == bidamount+ fees);
        payable(collector).transfer(fees);
        uint token_id = idToAuctionItem[newauctionIds].tokenId;
        uint numberOfUnits = max_supply[token_id];
       history_Aa[newauctionIds].push(msg.sender);
       history_Ap[newauctionIds].push(bidamount);
       history_At[newauctionIds].push(block.timestamp);
       history_Aamt[newauctionIds].push(numberOfUnits);
       uint bidAddress = history_Aa[newauctionIds].length;
        if (bidAddress==1) {
           payable(address(this)).transfer(bidamount); 
           idToAuctionItem[newauctionIds].hightestbid = bidamount;
           idToAuctionItem[newauctionIds].hightestbidderAddress = payable (address (msg.sender));

        } else {
            payable(address(this)).transfer(bidamount);
            payable(idToAuctionItem[newauctionIds].hightestbidderAddress).transfer(idToAuctionItem[newauctionIds].hightestbid);
           idToAuctionItem[newauctionIds].hightestbid = bidamount;
           idToAuctionItem[newauctionIds].hightestbidderAddress = payable (address (msg.sender));
        }
    }
    function endAuction (uint newauctionIds) public {
        require(block.timestamp > idToAuctionItem[newauctionIds].endtime, "Auction not end");
        require (msg.sender == collector,"the owner has a right");
        uint _tokenID = idToAuctionItem[newauctionIds].tokenId;
        uint _numberOfUnit = max_supply[_tokenID];
        address _seller = idToAuctionItem[newauctionIds].seller;
        address bidder = idToAuctionItem[newauctionIds].hightestbidderAddress;
        uint bidAddress = history_Aa[newauctionIds].length;

        if (bidAddress==0) {
             _safeTransferFrom(address(this),idToAuctionItem[newauctionIds].seller,_tokenID,_numberOfUnit,"");
        } else {
          payable(_seller).transfer(idToAuctionItem[newauctionIds].hightestbid);
          _safeTransferFrom(address(this),bidder,_tokenID,_numberOfUnit,"");
          history_a[_tokenID].push(msg.sender);//history
          history_p[_tokenID].push(idToAuctionItem[newauctionIds].hightestbid);
          history_t[_tokenID].push(block.timestamp);
          history_amt[_tokenID].push(_numberOfUnit);  
        }
        lastendAuction = newauctionIds;
    }
    /*function isAuctionLiveBuyout(uint newauctionIds) public view returns (bool){
            //address Seller = idToAuctionItem[newauctionIds].seller;
            uint token = idToAuctionItem[newauctionIds].tokenId;
            balanceOf(address(this),token)== max_supply[token];
            return true;
    }*/
    function isAuctionLive(uint newauctionIds) public view returns (bool){
        if(idToAuctionItem[newauctionIds].endtime > block.timestamp){
         return true; }
         else {return false;}
    }

    function feeForAuction(uint _pricePerUnit,uint numberOfUnit) public view returns (uint FeeForAuction){
         uint totalAmount = numberOfUnit*_pricePerUnit;
         uint fee = (Platfrom_fees*totalAmount)/100;
        // uint auction_fee = 0.1 ether;
         FeeForAuction = fee + Auction_fee;
         
    }
    function feeForbid(uint bidamount) pure public  returns (uint FeeForbid) {
        FeeForbid =  bidamount + 0.25 ether;
    }
    function Buynow (uint auctionId) payable public{
        require(idToAuctionItem[auctionId].endtime > block.timestamp, "Auction is end");
        require (_Buynow[auctionId] == true," Not a BuyNow Auction");
        uint fees = 0.25 ether;
        uint amount = idToAuctionItem[auctionId].buynowAmount;
        require (msg.value == fees + amount,"Check the amount sending");
        payable(collector).transfer(fees);
        uint token_id = idToAuctionItem[auctionId].tokenId;
        uint numberOfUnits = max_supply[token_id];
        address _seller = idToAuctionItem[auctionId].seller;
        address bidder = idToAuctionItem[auctionId].hightestbidderAddress;
        uint bidAddress = history_Aa[auctionId].length;
        idToAuctionItem[auctionId].endtime = block.timestamp;
         if (bidAddress==0) {
             _safeTransferFrom(address(this),msg.sender,token_id,numberOfUnits,"");
             payable(_seller).transfer(amount);
             }
        else {
            payable(bidder).transfer(idToAuctionItem[auctionId].hightestbid);
            payable(_seller).transfer(amount);
            _safeTransferFrom(address(this),msg.sender,token_id,numberOfUnits,"");
             history_a[token_id].push(msg.sender);//history
            history_p[token_id].push(amount);
            history_t[token_id].push(block.timestamp);
             history_amt[token_id].push(numberOfUnits);  

             }

    }
    function buynowFees(uint auctionId) public view returns (uint fees) {
        uint amount = idToAuctionItem[auctionId].buynowAmount;
        fees = amount+ 0.25 ether;

    }

    function fetchmyNft() public view returns (uint [] memory){ 
       uint totalToken = tokenIds.current();
       uint itemcount;
       uint current = 0;
       for (uint i =0; i <totalToken;i++){
           if (balanceOf(msg.sender,i+1)>0){
               itemcount +=1;
           }   
       }
        uint [] memory items = new uint [](itemcount);
        for (uint i =0; i <totalToken;i++){
         if (balanceOf(msg.sender,i+1)>0){
             uint currentid = i+1;
           items[current]  = currentid;
           current +=1;
         }   
        }
        return items;
}
    function fetchTradeItem() public view returns(MarketItem[] memory){
        uint TradeItemCount = itemIds.current();
        uint activeTradeCount =0;
        uint current =0;
        for (uint i=0; i< TradeItemCount; i++){
            if(idToMarketItem[i+1].units_left > 0){
                activeTradeCount +=1;
            }
        }
        MarketItem[] memory items1 = new MarketItem[](activeTradeCount);
        for (uint i=0; i< TradeItemCount; i++){
             if(idToMarketItem[i+1].units_left > 0){
                uint currentId = idToMarketItem[i+1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items1[current] = currentItem;
                current +=1;
             }
        }
        return items1;
}
    function fetchAuctionItem() public view returns (AuctionItem[] memory){
        uint AuctionItemCount = auctionIds.current();
        uint activeAuctionCount =0;
        uint current1 = 0;
        for (uint i=0; i<AuctionItemCount; i++){
            if(idToAuctionItem[i+1].endtime > block.timestamp){
                activeAuctionCount +=1;
            }
        }
        AuctionItem[] memory items1 = new AuctionItem[](activeAuctionCount);
        for (uint i=0; i<AuctionItemCount; i++){
            if(idToAuctionItem[i+1].endtime > block.timestamp){
                uint currentId1 = idToAuctionItem[i+1].auctionId;
                AuctionItem storage currentItem = idToAuctionItem[currentId1];
                items1[current1] = currentItem;
                current1 +=1;
            }
            }
            return items1;
    }
    function fetchmyListedTrade() public view returns(MarketItem[] memory){
         uint TradeItemCount = itemIds.current();
        uint activeTradeCount =0;
        uint current =0;
        for (uint i=0; i< TradeItemCount; i++){
            if(idToMarketItem[i+1].seller ==msg.sender){
                activeTradeCount +=1;
            }
        }
        MarketItem[] memory items1 = new MarketItem[](activeTradeCount);
        for (uint i=0; i< TradeItemCount; i++){
             if(idToMarketItem[i+1].seller ==msg.sender){
                uint currentId = idToMarketItem[i+1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items1[current] = currentItem;
                current +=1;
             }
        }
        return items1;

    }
    function fetchmyListedAuction() public view returns(AuctionItem[] memory){
         uint AuctionItemCount = auctionIds.current();
        uint activeAuctionCount =0;
        uint current1 = 0;
        for (uint i=0; i<AuctionItemCount; i++){
            if(idToAuctionItem[i+1].seller == msg.sender){
                activeAuctionCount +=1;
            }
        }
         AuctionItem[] memory items1 = new AuctionItem[](activeAuctionCount);
        for (uint i=0; i<AuctionItemCount; i++){
            if(idToAuctionItem[i+1].seller == msg.sender){
                uint currentId1 = idToAuctionItem[i+1].auctionId;
                AuctionItem storage currentItem = idToAuctionItem[currentId1];
                items1[current1] = currentItem;
                current1 +=1;
            }
            }
            return items1;
    }
   function super_mint(address _to,uint _amount,string memory _uri,uint _intial_price, uint buyVail) public {
   tokenIds.increment();
   uint newtokenIds = tokenIds.current();
   require(msg.sender == collector,"Not an owner");
    _mint(_to, newtokenIds, _amount, "");
    _setURI(newtokenIds,_uri);
    //payable(collector).transfer(_intial_price);
    max_supply[newtokenIds] = _amount;
    intial_price[newtokenIds]= _intial_price;
    current_supply[newtokenIds] = _amount;
    Mint_time[newtokenIds] = block.timestamp;
    VaildFor[newtokenIds] = buyVail;
    Minter_address[newtokenIds]= msg.sender;
    setApprovalForAll(address(this),true);
    }
    
    function increase_auction_time(uint AuctionId,uint number_of_days)public {
        address Seller = idToAuctionItem[AuctionId].seller;
        require(msg.sender == Seller,"Not a Seller" );
        uint NewEndtime = idToAuctionItem[AuctionId].endtime + (number_of_days * 86400);
        idToAuctionItem[AuctionId].endtime = NewEndtime;
    }

    function update_auction_fee(uint fee) public {
        require (msg.sender == collector,"Not an Owner");
        Auction_fee = fee;
        
    }

    }