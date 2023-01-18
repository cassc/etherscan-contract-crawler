// contracts/NFTMarketplace.sol
// SPDX-License-Identifier: MIT OR Apache-2.0
// by @giulibardecio

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "hardhat/console.sol";

contract NFTMarketplaceV3 is ReentrancyGuard {

  using Counters for Counters.Counter;
  Counters.Counter private _itemCounter; //start from 1
  Counters.Counter private _itemSoldCounter; 
  Counters.Counter private _itemCounterCocreator; //start from 1
  address public DAO; // @notice DAO address
  IERC20 public token;  // @notice the token used for payment
  address payable public marketowner; // @notice the owner of the marketplace
  uint256 public marketFee; // @notice percentage of comission that the DAO takes 2.5%

  enum State { Created, Release, Inactive } // @notice the state of the NFT (1 , 2, 3) -> (ActiveListing, Sold, Inactive)

  struct Cocreator {
    address payable cocreator;
    uint256 share;
  }

  mapping(uint256 => Cocreator) private cocreatorsMapping; //agregar id al cocreador 
  struct MarketItem {
    uint uid;
    address nftContract;
    uint256 tokenId;
    address payable seller;
    address payable buyer;
    uint256 [] cocreators;
    uint256 price;
    State state;
  }

  mapping(uint256 => MarketItem) private marketItems;

  event MarketItemCreated (
    uint indexed uid,
    address indexed nftContract,
    uint256 indexed tokenId,
    address seller,
    address buyer,
    uint256[] cocreators,
    uint256 price,
    State state
  );

  event MarketItemSold (
    uint indexed uid,
    address indexed nftContract,
    uint256 indexed tokenId,
    address seller,
    address buyer,
    uint256[] cocreators,
    uint256 price,
    State state
  );

  constructor(address dao, address _token, uint _marketFee) {
    marketowner = payable(msg.sender);
    DAO = dao;
    token = IERC20(_token);
    marketFee = _marketFee;
  }

  /**
   * @dev Returns the market fee of the marketplace
   */
  function getMarketFee() public view returns (uint256) {
    return marketFee;
  }

  function calculateMarketFee(uint256 _price) public view returns (uint256) {
    return (_price * marketFee) / 10000;
  }

  function calculateSplit(uint256 percentage, uint256 _price) public view returns (uint256) {
    return (_price * percentage) / 10000;
  }

  /**
   * @dev transfer the market fee to the DAO
   * return the amount left to be paid to the seller/s after the fee discount
   */
  function deduceMarketFee(address buyer, uint256 grossSaleValue) internal returns (uint256 netSaleAmount) {
      uint256 marketFeeAmount = calculateMarketFee(grossSaleValue);
      uint256 netSaleValue = grossSaleValue - marketFeeAmount;
      token.transferFrom(buyer, DAO, marketFeeAmount);
      return netSaleValue;
  }

  event TransferRoy(address indexed from, address indexed to, uint256[] roy);
  function deduceRoyalties(address buyer, uint256 grossSaleValue,  Cocreator[] memory royalties) internal returns (uint256 netSaleAmount) {
      uint256 totalSharesRoy = 0;
      for (uint256 i = 0; i < royalties.length; i++) {
          totalSharesRoy += royalties[i].share;
      }
      uint256[] memory royalty = new uint256[](royalties.length);
      for (uint256 i = 0; i < royalties.length; i++) {
          token.transferFrom(buyer , royalties[i].cocreator, ((grossSaleValue * royalties[i].share) / 10000)); 
          royalty[i] = ((grossSaleValue * royalties[i].share) / 10000);
      }
      emit TransferRoy(buyer, address(this), royalty);
      uint256 netSaleValue = grossSaleValue - ((totalSharesRoy * grossSaleValue) / 10000);
      return netSaleValue;
  }

  event TransferSplit(address indexed from, address indexed to, uint256[] shares);
  function splitPayment(address buyer, uint256 grossSaleValue,  uint256[] memory cocreators) internal {
      uint256 totalShares = 0;
      for (uint256 i = 0; i < cocreators.length; i++) {
          totalShares += cocreatorsMapping[cocreators[i]].share;
      }
      uint256[] memory shares = new uint256[](cocreators.length);
      for (uint256 i = 0; i < cocreators.length; i++) {
          token.transferFrom(buyer, cocreatorsMapping[cocreators[i]].cocreator, (grossSaleValue *  cocreatorsMapping[cocreators[i]].share) / totalShares);  
          shares[i] = (grossSaleValue *  cocreatorsMapping[cocreators[i]].share) / totalShares;
      }
      emit TransferSplit(buyer, address(this), shares);
  }
  
  /**
   * @dev create a MarketItem for NFT sale on the marketplace.
   * 
   * List an NFT.
   */
  function createMarketItem(address nftContract, uint256 tokenId, Cocreator[] memory _cocreators, uint256 price) public payable nonReentrant {
    require(price > 0, "Price must be at least 1 wei");
    require(IERC721(nftContract).isApprovedForAll(msg.sender, address(this)), "NFT must be approved to market"); // change to approve mechanism from the original direct transfer to market

    _itemCounter.increment();
    uint256 id = _itemCounter.current();
  
    // cocreators storage; hacer for para crear cocreators
    uint256[] memory cocreators = new uint256[](_cocreators.length);
    for (uint i = 0; i < _cocreators.length; i++) {
      _itemCounterCocreator.increment();
      uint256 id2 = _itemCounterCocreator.current();
      cocreatorsMapping[id2] = Cocreator(_cocreators[i].cocreator, _cocreators[i].share);
      cocreators[i] = id2;
    }
    marketItems[id] =  MarketItem(
      id,
      nftContract,
      tokenId,
      payable(msg.sender),
      payable(address(0)),
      cocreators,
      price,
      State.Created
    );

    emit MarketItemCreated(
      id,
      nftContract,
      tokenId,
      msg.sender,
      address(0),
      cocreators,
      price,
      State.Created
    );
  }

  /**
   * @dev delete a MarketItem from the marketplace.
   * 
   * de-List an NFT.
   * 
   * todo ERC721.approve can't work properly!! comment out
   */
  function deleteMarketItem(uint256 itemId) public nonReentrant {
    require(itemId <= _itemCounter.current(), "id must <= item count");
    require(marketItems[itemId].state == State.Created, "item must be on market");
    MarketItem storage item = marketItems[itemId];

    require(item.seller == msg.sender, "Not seller");

    item.state = State.Inactive;

    emit MarketItemSold(
      itemId,
      item.nftContract,
      item.tokenId,
      item.seller,
      address(0),
      item.cocreators,
      0,
      State.Inactive
    );

  }

  /**
   * @dev (buyer) buy a MarketItem from the marketplace.
   * Transfers ownership of the item, as well as funds
   * NFT:         seller    -> buyer
   * value:       buyer     -> seller
   * marketFee:  contract  -> marketowner
   */
  function createMarketSale(address nftContract, uint256 id, uint256 amount, Cocreator[] memory royalties) public payable nonReentrant {

    MarketItem storage item = marketItems[id];
    uint price = item.price;
    uint tokenId = item.tokenId;
    uint[] memory cocreators = item.cocreators;

    require(item.state == State.Created, "Item must be on market");
    require(amount == price, "Please submit the asking price");
    require(IERC721(nftContract).isApprovedForAll(item.seller, address(this)), "NFT must be approved to market");

    item.buyer = payable(msg.sender);
    item.state = State.Release;
    _itemSoldCounter.increment();   

    // transfer % to DAO
    uint256 saleValueAfterFee = deduceMarketFee(msg.sender, price);
    
    // transfer royalties to cocreators
    uint256 saleValueAfterRoyalties = deduceRoyalties(msg.sender, saleValueAfterFee, royalties);
  
    // transfer the rest to sellers
    splitPayment(msg.sender, saleValueAfterRoyalties, cocreators);

    // transfer NFT to buyer
    IERC721(nftContract).transferFrom(item.seller, msg.sender, tokenId);

    emit MarketItemSold(
      id,
      nftContract,
      tokenId,
      item.seller,
      msg.sender,
      item.cocreators,
      price,
      State.Release
    );    
  }

  /**
   * @dev Returns all unsold market items
   * condition: 
   *  1) state == Created
   *  2) buyer = 0x0
   *  3) still have approve
   */
  function fetchActiveItems() public view returns (MarketItem[] memory) {
    return fetchHepler(FetchOperator.ActiveItems, address(0));
  }

  /**
   * @dev Returns only market items a user has purchased
   * todo pagination
   */
  function fetchPurchasedItems(address user) public view returns (MarketItem[] memory) {
    return fetchHepler(FetchOperator.MyPurchasedItems, user);
  }

  /**
   * @dev Returns only market items a user has created
   * todo pagination
  */
  function fetchCreatedItems(address user) public view returns (MarketItem[] memory) {
    return fetchHepler(FetchOperator.MyCreatedItems, user);
  }

  enum FetchOperator { ActiveItems, MyPurchasedItems, MyCreatedItems}

  /**
   * @dev fetch helper
   * todo pagination   
   */
   function fetchHepler(FetchOperator _op, address user) private view returns (MarketItem[] memory) {     
    uint total = _itemCounter.current();

    uint itemCount = 0;
    for (uint i = 1; i <= total; i++) {
      if (isCondition(marketItems[i], _op, user)) {
        itemCount ++;
      }
    }

    uint index = 0;
    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint i = 1; i <= total; i++) {
      if (isCondition(marketItems[i], _op, user)) {
        items[index] = marketItems[i];
        index ++;
      }
    }
    return items;
  } 

  /**
   * @dev helper to build condition
   *
   * todo should reduce duplicate contract call here
   * (IERC721(item.nftContract).getApproved(item.tokenId) called in two loop
   */
  function isCondition(MarketItem memory item, FetchOperator _op, address user) private view returns (bool){
    if(_op == FetchOperator.MyCreatedItems){ 
      return 
        (item.seller == user
          && item.state != State.Inactive
        )? true
         : false;
    }else if(_op == FetchOperator.MyPurchasedItems){
      return
        (item.buyer ==  user) ? true: false;
    }else if(_op == FetchOperator.ActiveItems){
      return 
        (item.buyer == address(0) 
          && item.state == State.Created
        )? true
         : false;
    }else{
      return false;
    }
  }

  // function to get Cocreators
  function getCocreators(uint256[] memory ids) public view returns (Cocreator[] memory) {
    uint total = ids.length;
    Cocreator[] memory cocreators = new Cocreator[](total);
    for (uint i = 0; i < total; i++) {
      cocreators[i] = cocreatorsMapping[ids[i]];
    }
    return cocreators;
  }

}