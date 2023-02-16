// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IERC2981.sol";
import "./interfaces/ISageMarket.sol";

contract SageMarket is ReentrancyGuard, ISageMarket,ERC1155Holder,Ownable,AccessControl {
  using Counters for Counters.Counter;
  Counters.Counter private _itemIds;
  Counters.Counter private _itemsSold;
  Counters.Counter private _itemsCancel;

  uint256 private _marketplaceFee;
  address private _marketplaceFeeRecipient;
  bytes4  private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");


  constructor(uint256 fee, address feeRecipient) {
    _marketplaceFee = fee;
    _marketplaceFeeRecipient = feeRecipient;
    _setupRole(ADMIN_ROLE, msg.sender);
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  struct MarketItem {
    uint256 itemId;
    address nftContract;
    uint256 tokenId;
    address payable seller;
    address payable owner;
    uint256 price;
    bool onSale;
    uint256 amount;
    uint8 tokenType; // 0 is ERC721, 1 is ERC1155
  }

  mapping(uint256 => MarketItem) private idToMarketItem;

  
  function createMarketItem(
    address nftContract,
    uint256 tokenId,
    uint256 price
  ) public payable nonReentrant {
    require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not a admin");
    require(price > 0, "Price must be at least 1 wei");
    require(IERC721(nftContract).isApprovedForAll(msg.sender,address(this)) == true, "You are not approve the smart contract");
    _itemIds.increment();
    uint256 itemId = _itemIds.current();
    IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

    idToMarketItem[itemId] =  MarketItem(
      itemId,
      nftContract,
      tokenId,
      payable(msg.sender),
      payable(address(0)),
      price,
      true,
      1,
      0
    );
    

    emit CreateMarketItem(
      itemId,
      nftContract,
      tokenId,
      msg.sender,
      price,
      true,
      1,
      0
    );
  }


  /// @notice It will list the NFT to marketplace.
  /// @dev It will list NFT minted from MFTMint contract.        
  function createMarketItem1155( 
    address nftContract,
    uint256 tokenId,
    uint256 price,
    uint256 amount) public nonReentrant{
      require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not a admin");
      require(price > 0, "Price must be at least 1 wei");
      require(IERC1155(nftContract).isApprovedForAll(msg.sender,address(this)) == true, "You are not approve the smart contract");
      _itemIds.increment();
      uint256 itemId = _itemIds.current();

      idToMarketItem[itemId] =  MarketItem(
        itemId,
        nftContract,
        tokenId,
        payable(msg.sender),
        payable(address(0)),
        price,
        true,
        amount,
        1
      );
      IERC1155(nftContract).safeTransferFrom(msg.sender, address(this), tokenId, amount, "");

      emit CreateMarketItem(
        itemId,
        nftContract,
        tokenId,
        msg.sender,
        price,
        true,
        amount,
        1
      );

  }

  function createMarketSale(
    uint256 itemId
    ) public payable nonReentrant {
    require(idToMarketItem[itemId].onSale == true, "The sale is close");
    require(msg.sender != idToMarketItem[itemId].seller , "You can not buy your NFT");
    require(idToMarketItem[itemId].tokenType == 0, "Sale type is ERC721");
    address nftContract = idToMarketItem[itemId].nftContract;
    uint price = idToMarketItem[itemId].price;
    uint tokenId = idToMarketItem[itemId].tokenId;
    uint256 fee = (price * _marketplaceFee) / 10000;
    address seller = idToMarketItem[itemId].seller;
    require(msg.value == price, "Please submit the asking price in order to complete the purchase");


    if(checkRoyalties(idToMarketItem[itemId].nftContract)){
        (address royaltyRecipent, uint256 royaltiesAmount) = IERC2981(nftContract).royaltyInfo(0,price);
        idToMarketItem[itemId].seller.transfer(msg.value - fee - royaltiesAmount);
        payable(royaltyRecipent).transfer(royaltiesAmount);
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        idToMarketItem[itemId].owner = payable(msg.sender);
        idToMarketItem[itemId].onSale = false;
        _itemsSold.increment();
        payable(_marketplaceFeeRecipient).transfer(fee);
        
    }    
    else{
        idToMarketItem[itemId].seller.transfer(msg.value - fee);
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        idToMarketItem[itemId].owner = payable(msg.sender);
        idToMarketItem[itemId].onSale = false;
        _itemsSold.increment();
        payable(_marketplaceFeeRecipient).transfer(fee);
    }
    emit CreateMarketSale (
      itemId,
      nftContract,
      tokenId,
      seller,
      msg.sender,
      price,
      false,
      fee,
      1
    );
  }

  function createMarketSale1155(
    uint256 itemId,
    uint256 amount
    ) public payable nonReentrant {
    require(idToMarketItem[itemId].onSale == true, "The sale is close");
    require(msg.sender != idToMarketItem[itemId].seller , "You can not buy your NFT");
    require(idToMarketItem[itemId].tokenType == 1, "Sale type is ERC1155");
    require(amount <= idToMarketItem[itemId].amount , "NFT amount is to big");
    address nftContract = idToMarketItem[itemId].nftContract;
    uint price = idToMarketItem[itemId].price * amount;
    uint tokenId = idToMarketItem[itemId].tokenId;
    uint256 fee = (price * _marketplaceFee) / 10000;
    address seller = idToMarketItem[itemId].seller;
    require(msg.value == idToMarketItem[itemId].price * amount, "Please submit the asking price in order to complete the purchase");


    if(checkRoyalties(idToMarketItem[itemId].nftContract)){
        (address royaltyRecipent, uint256 royaltiesAmount) = IERC2981(nftContract).royaltyInfo(0,price);
        idToMarketItem[itemId].seller.transfer(msg.value - fee - royaltiesAmount);
        payable(royaltyRecipent).transfer(royaltiesAmount);
        IERC1155(nftContract).safeTransferFrom(address(this), msg.sender, tokenId,amount,"");
        
        if (amount == idToMarketItem[itemId].amount){
          idToMarketItem[itemId].owner = payable(msg.sender);
          idToMarketItem[itemId].onSale = false;
        }
        else{
          payable(msg.sender);
          idToMarketItem[itemId].amount = idToMarketItem[itemId].amount - amount;
        }
        
        _itemsSold.increment();
        payable(_marketplaceFeeRecipient).transfer(fee);
        
    }    
    else{
        idToMarketItem[itemId].seller.transfer(msg.value - fee);
        IERC1155(nftContract).safeTransferFrom(address(this), msg.sender, tokenId,amount,"");

        if (amount == idToMarketItem[itemId].amount){
          idToMarketItem[itemId].owner = payable(msg.sender);
          idToMarketItem[itemId].onSale = false;
        }
        else{
          payable(msg.sender);
          idToMarketItem[itemId].amount = idToMarketItem[itemId].amount - amount;
        }
        _itemsSold.increment();
        payable(_marketplaceFeeRecipient).transfer(fee);
    }
    emit CreateMarketSale (
      itemId,
      nftContract,
      tokenId,
      seller,
      msg.sender,
      price,
      false,
      fee,
      amount
    );
  }

  function cancelSale(    
    uint256 itemId
    ) public  nonReentrant {

    address nftContract = idToMarketItem[itemId].nftContract;
    uint tokenId = idToMarketItem[itemId].tokenId;
    require(msg.sender == idToMarketItem[itemId].seller, "You are not the owner of this nft");
    require(idToMarketItem[itemId].onSale == true, "The sale is already close");
    idToMarketItem[itemId].onSale = false;

    if(idToMarketItem[itemId].tokenType ==0){ 
      IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
    } 
    else{
    IERC1155(nftContract).safeTransferFrom(address(this), msg.sender, tokenId,idToMarketItem[itemId].amount,"");
    }
    _itemsCancel.increment();
     
    emit CancelMarketItem (
      itemId,
      nftContract,
      tokenId,
      msg.sender,
      false
    );
  }


  function getMarketItem(uint256 marketItemId) public view returns (MarketItem memory) {
    return idToMarketItem[marketItemId];
  }

  function fetchMarketItems() public view returns (MarketItem[] memory) {
    uint itemCount = _itemIds.current();
    uint unsoldItemCount = _itemIds.current() - _itemsSold.current() -_itemsCancel.current();
    uint currentIndex = 0;

    MarketItem[] memory items = new MarketItem[](unsoldItemCount);
    for (uint i = 0; i < itemCount; i++) {
      if (idToMarketItem[i + 1].onSale == true) {
        uint currentId = idToMarketItem[i + 1].itemId;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
   
    return items;
  }

  function fetchMyNFTs() public view returns (MarketItem[] memory) {
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
        uint currentId = idToMarketItem[i + 1].itemId;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
   
    return items;
  }
  

  function checkRoyalties(address _contract) public view returns (bool) {
      (bool success) = IERC165(_contract).supportsInterface(_INTERFACE_ID_ERC2981);
      return success;
  }

  function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl,ERC1155Receiver)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}