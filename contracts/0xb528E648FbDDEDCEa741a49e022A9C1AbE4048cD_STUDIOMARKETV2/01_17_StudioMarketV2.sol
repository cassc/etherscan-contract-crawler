/**
 *Submitted for verification at Etherscan.io on 2022-05-03
 */

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';

contract STUDIOMARKETV2 is ReentrancyGuard, ERC721URIStorage, Ownable {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;
  Counters.Counter private _itemsSold;

  ///listing percentage is multiplied by 10 to support dynamic percentage update
  /// @dev get atual percentage by dividing value with 10
  uint256 listingPercentage = 25;

  bool _takeFees = true;
  bool _tokenActive = false;

  mapping(uint256 => MarketItem) private idToMarketItem;

    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        address payable creator;
        uint256 price;
        uint256 tokens;
        address[] rAddress;
        uint256[] rFee;
        bool sold;
    }

  event MarketItemCreated(uint256 indexed tokenId, address seller, address owner, address creator, uint256 price, bool sold);
  event MarketItemListed(uint256 tokenId, address seller, uint256 price, uint256 tokens);
  event MarketItemRemoved(uint256 indexed tokenId);
  event TokenTransferred(address indexed previousOwner, address indexed newOwner, uint256 indexed tokenId);

  constructor() ERC721('XSTUDIO', 'TXS') {}

  /* Updates the listing price of the contract */
  function updateListingPrice(uint256 _listingPrice) public onlyOwner {
    //validate _listingPrice value
    require(_listingPrice <= 500, 'Value Overflow: Stated Value Is Above 50 percent');

    listingPercentage = _listingPrice;
  }

  /* Returns the listing price of the contract */
  function getListingPrice() public view returns (uint256) {
    return listingPercentage;
  }

  /**
   * @dev Private function because it simply calculates commission and pays out accordingly.
   * Inputs & other validation likely will come from somewhere else in the contract.
   *
   * Handles All the payments and fees distribution
   *
   * Note: Numbers are multiplied by 10 in order to calculate dynamic tradefee percentages and avert solidity fixed integer issues
   */

  function takeCommission(
    address seller,
    address platform,
    uint256 amountPaid,
    uint256 commissionPercentage,
    address[] memory _royaltyAddress, 
    uint256[] memory _royaltyFee
  ) private {
    //validate royalty value
    require(_royaltyAddress.length == _royaltyFee.length, 'Royalty Addresses And Fees Must Be Same Length');

    uint256 totalPayment = amountPaid;

    // divide by 1000 because commission percentage is expressed as a uint * 10
    uint256 platformFee = (totalPayment * commissionPercentage) / 1000;

    amountPaid -= platformFee;

    payable(platform).transfer(platformFee);

    if (_royaltyAddress.length == 0) {
      payable(seller).transfer(amountPaid);
    } else {

        for (uint256 i = 0; i < _royaltyAddress.length; i++) {

            if (_royaltyFee[i] > 0) {

                // divide by 1000 because commission percentage is expressed as a uint * 10
                uint256 royalPercent = (_royaltyFee[i] * totalPayment) / 1000;
                amountPaid -=  royalPercent; 

                payable(_royaltyAddress[i]).transfer(royalPercent);
                         
            }
        }

        payable(seller).transfer(amountPaid);
    }

  }

  function takeTokenCommission(
    address seller,
    address platform,
    uint256 tokens,
    uint256 commissionPercentage,
    address[] memory _royaltyAddress, 
    uint256[] memory _royaltyFee,
    address tokenContract
  ) private {
    //validate royalty value
    require(_royaltyAddress.length == _royaltyFee.length, 'Royalty Addresses And Fees Must Be Same Length');

    // divide by 1000 because commission percentage is expressed as a uint * 10
    uint256 platformFee = (tokens * commissionPercentage) / 1000;

    if (_takeFees == true) {
      tokens -= platformFee;
      IERC20(tokenContract).transferFrom(msg.sender, platform, platformFee);
    }

    //distribute tokens if takefees is true
    if (_royaltyAddress.length == 0) {
      IERC20(tokenContract).transferFrom(msg.sender, seller, tokens);
    } else {

      for (uint256 i = 0; i < _royaltyAddress.length; i++) {
            if (_royaltyFee[i] > 0) {
                // divide by 1000 because commission percentage is expressed as a uint * 10
                uint256 royalPercent = (_royaltyFee[i] * tokens) / 1000;
                tokens -=  royalPercent; 

                IERC20(tokenContract).transferFrom(seller,_royaltyAddress[i], royalPercent);
                tokens -=  _royaltyFee[i];          
            }
        }

      IERC20(tokenContract).transferFrom(msg.sender, seller, tokens);
    }
  }

  function royaltyFee(uint256 tokenId)
        external
        view
        returns (address[] memory, uint256[] memory)
    {
        address[] memory addr = idToMarketItem[tokenId].rAddress;
        uint256[] memory fee =  idToMarketItem[tokenId].rFee;
        return (addr, fee);
    }

  /* Creates the sale of a marketplace item */
  /* Transfers ownership of the item, as well as funds between parties */
  function mintTokenTXS(
    string memory tokenURI,
    address creator,
    uint256 price,
    uint256 tokens,
    address[] memory _royaltyAddress,
    uint256[] memory _royaltyFee,
    address tokenContract
  ) public nonReentrant  {
    require(tokens <= IERC20(tokenContract).balanceOf(msg.sender), 'not enough  tokens');
    require(tokens > 0, 'Token Price Must Be Greater Than Zero');
    require(price > 0, 'Price must be at least 1 wei');

    _tokenIds.increment();
    uint256 newTokenId = _tokenIds.current();
    _mint(msg.sender, newTokenId);
    _setTokenURI(newTokenId, tokenURI);
    _itemsSold.increment();

    idToMarketItem[newTokenId] = MarketItem(newTokenId, payable(creator), payable(msg.sender), payable(creator), price, tokens, _royaltyAddress, _royaltyFee , false);

    //finish transaction and transfer token
    takeTokenCommission(creator, owner(), tokens, listingPercentage, _royaltyAddress, _royaltyFee, tokenContract);

    emit MarketItemCreated(newTokenId, address(this), msg.sender, creator, price, false);
  }

  /* Mints a token and lists it in the marketplace */
  function mintToken(
    string memory tokenURI,
    address creator,
    uint256 price,
    uint256 tokens,
    address[] memory _royaltyAddress,
    uint256[] memory _royaltyFee
  ) public payable nonReentrant {
    require(price > 0, 'Price must be at least 1 wei');
    require(msg.value == price, 'Please submit the asking price in order to complete the purchase');
    if (_tokenActive == true) {
      require(tokens > 0, 'Token Price Must Be Greater Than Zero');
    }
    _tokenIds.increment();
    uint256 newTokenId = _tokenIds.current();

    _mint(msg.sender, newTokenId);
    _setTokenURI(newTokenId, tokenURI);
    _itemsSold.increment();

    idToMarketItem[newTokenId] = MarketItem(newTokenId, payable(creator), payable(msg.sender), payable(creator), price, tokens, _royaltyAddress, _royaltyFee, false);

    takeCommission(creator, owner(), price, listingPercentage, _royaltyAddress, _royaltyFee);

    emit MarketItemCreated(newTokenId, address(this), msg.sender, creator, price, false);
  }

  /* Creates the sale of a marketplace item */
  /* Transfers ownership of the item, as well as funds between parties */
  function buyToken(uint256 tokenId) public payable nonReentrant {
    uint256 price = idToMarketItem[tokenId].price;
    address[] memory _royaltyAddress = idToMarketItem[tokenId].rAddress;
    uint256[] memory _royaltyFee = idToMarketItem[tokenId].rFee;
    address seller = idToMarketItem[tokenId].seller;

    require(msg.value == price, 'Please submit the asking price in order to complete the purchase');
    idToMarketItem[tokenId].owner = payable(msg.sender);
    idToMarketItem[tokenId].sold = true;
    idToMarketItem[tokenId].seller = payable(address(this));
    _itemsSold.increment();
    _transfer(address(this), msg.sender, tokenId);

    //finish transaction and pay respective parties

    takeCommission(seller, owner(), price, listingPercentage, _royaltyAddress, _royaltyFee);

    //emit market sales event
    emit TokenTransferred(seller, msg.sender, tokenId);
  }

  /* allows someone to purchase a listed token */
  function buyTokenTXS(uint256 tokenId, address tokenContract) public nonReentrant {
    uint256 tokens = idToMarketItem[tokenId].tokens;
    address seller = idToMarketItem[tokenId].seller;
    address[] memory _royaltyAddress = idToMarketItem[tokenId].rAddress;
    uint256[] memory _royaltyFee = idToMarketItem[tokenId].rFee;

    require(tokens <= IERC20(tokenContract).balanceOf(msg.sender), 'not enough tokens');
    require(tokens > 0, 'token option is not active for this asset yet!');

    idToMarketItem[tokenId].sold = false;
    idToMarketItem[tokenId].owner = payable(msg.sender);
    idToMarketItem[tokenId].seller = payable(address(this));
    _itemsSold.increment();
    _transfer(address(this), msg.sender, tokenId);

    //finish transaction and transfer token
    takeTokenCommission(seller, owner(), tokens, listingPercentage, _royaltyAddress, _royaltyFee, tokenContract);

    //emit market sales event
    emit TokenTransferred(seller, msg.sender, tokenId);
  }

  /* allows someone to resell a token they have purchased */
  function resellToken(
    uint256 tokenId,
    uint256 price,
    uint256 tokens
  ) public nonReentrant {
    require(idToMarketItem[tokenId].owner == msg.sender, 'Only item owner can perform this operation');
    require(price > 0, 'Price must be at least 1 wei');
    if (_tokenActive == true) {
      require(tokens > 0, 'Token Price Must Be Greater Than Zero');
    }

    idToMarketItem[tokenId].sold = false;
    idToMarketItem[tokenId].price = price;
    idToMarketItem[tokenId].tokens = tokens;
    idToMarketItem[tokenId].seller = payable(msg.sender);
    idToMarketItem[tokenId].owner = payable(address(this));
    _itemsSold.decrement();
    _transfer(msg.sender, address(this), tokenId);

    //emit market item add event
    emit MarketItemListed(tokenId, msg.sender, price, tokens);
  }

  // allows user to change the price of a listed token

  function changePrice(
    uint256 tokenId,
    uint256 _price,
    uint256 _tokens
  ) public {
    require(idToMarketItem[tokenId].seller == msg.sender, 'Only item owner can perform this operation');
    if (_tokenActive == true) {
      require(_tokens > 0, 'Token Price Must Be Greater Than Zero');
    }

    idToMarketItem[tokenId].price = _price;
    idToMarketItem[tokenId].tokens = _tokens;
  }

  /* allows someone to remove a token from the market */
  function delistItem(uint256 tokenId) public {
    require(idToMarketItem[tokenId].seller == msg.sender, 'Only item owner can perform this operation');
    idToMarketItem[tokenId].sold = false;
    idToMarketItem[tokenId].seller = payable(address(this));
    idToMarketItem[tokenId].owner = payable(msg.sender);
    _itemsSold.increment();
    _transfer(address(this), msg.sender, tokenId);

    //emit item removal event
    emit MarketItemRemoved(tokenId);
  }

  /* Returns all unsold market items */
  function fetchMarketItems() public view returns (MarketItem[] memory) {
    uint256 itemCount = _tokenIds.current();
    uint256 unsoldItemCount = _tokenIds.current() - _itemsSold.current();
    uint256 currentIndex = 0;

    MarketItem[] memory items = new MarketItem[](unsoldItemCount);
    for (uint256 i = 0; i < itemCount; i++) {
      if (idToMarketItem[i + 1].owner == address(this)) {
        uint256 currentId = i + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }

  /* Returns only items that a user has purchased */
  function fetchMyNFTs() public view returns (MarketItem[] memory) {
    uint256 totalItemCount = _tokenIds.current();
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

  /* Returns only items a user has listed */
  function fetchItemsListed() public view returns (MarketItem[] memory) {
    uint256 totalItemCount = _tokenIds.current();
    uint256 itemCount = 0;
    uint256 currentIndex = 0;

    for (uint256 i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].seller == msg.sender) {
        itemCount += 1;
      }
    }

    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint256 i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].seller == msg.sender) {
        uint256 currentId = i + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }

   function getMarketItem(uint256 marketItemId) public view returns (MarketItem memory) {
    return idToMarketItem[marketItemId];
  }

    //Use this in case Coins are sent to the contract by mistake
    function rescueETH(uint256 weiAmount) external onlyOwner {
        require(address(this).balance >= weiAmount, "insufficient Token balance");
        payable(msg.sender).transfer(weiAmount);
    }

    function rescueAnyERC20Tokens(
        address _tokenAddr,
        address _to,
        uint256 _amount
    ) public onlyOwner {
        IERC20(_tokenAddr).transfer(_to, _amount);
    }

    receive() external payable {}

//override ownership renounce function from ownable contract
  function renounceOwnership() public pure override(Ownable) {
    revert('Unfortunately you cannot renounce Ownership of this contract!');
  }
}