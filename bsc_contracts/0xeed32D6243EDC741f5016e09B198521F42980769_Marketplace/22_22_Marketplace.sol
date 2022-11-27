// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "@openzeppelin/contracts/utils/Counters.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";

contract Marketplace is
  Initializable,
  ReentrancyGuardUpgradeable,
  ERC721URIStorageUpgradeable,
  OwnableUpgradeable,
  UUPSUpgradeable
{
  using SafeMathUpgradeable for uint256;
  using CountersUpgradeable for CountersUpgradeable.Counter;
  CountersUpgradeable.Counter private _itemIds;
  CountersUpgradeable.Counter private _tokenIds;
  CountersUpgradeable.Counter private _itemsSold;

  // address public owner;

  // constructor() ERC721("SPORTOFI", "SPORTO") {
  //   owner = payable(msg.sender);
  // }
  uint256 exchangeFee;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    string calldata name_,
    string calldata symbol_
  ) external initializer {
    __ERC721_init(name_, symbol_);
    __ERC721URIStorage_init();
    __Ownable_init();
    __UUPSUpgradeable_init();
    exchangeFee = 50;
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

  event MarketItemCreated(
    uint indexed itemId,
    address indexed nftContract,
    uint256 indexed tokenId,
    address seller,
    address owner,
    uint256 price,
    bool sold
  );

  event MarketItemSold(uint indexed itemId, address owner);

  /* Updates the listing price of the contract */
  function updateListingPrice(uint256 _exchangeFee) public payable {
    require(owner() == msg.sender, "Only marketplace owner can update listing price.");
    exchangeFee = _exchangeFee;
  }

  /* Returns the listing price of the contract */
  function getListingPrice() public view returns (uint256) {
    return exchangeFee;
  }

  /* Mints a token and lists it in the marketplace */
  function createToken(string memory tokenURI_) public payable returns (uint256) {
    _tokenIds.increment();
    uint256 newTokenId = _tokenIds.current();

    _mint(msg.sender, newTokenId);
    _setTokenURI(newTokenId, tokenURI_);
    return newTokenId;
  }

  function createMarketItem(address nftContract, uint256 tokenId, uint256 price) public payable nonReentrant {
    require(price > 0, "Price must be greater than 0");

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

    IERC721Upgradeable(nftContract).transferFrom(msg.sender, address(this), tokenId);

    emit MarketItemCreated(itemId, nftContract, tokenId, msg.sender, address(0), price, false);
  }

  function createMarketSale(address nftContract, uint256 itemId) public payable nonReentrant {
    uint price = idToMarketItem[itemId].price;
    uint tokenId = idToMarketItem[itemId].tokenId;
    bool sold = idToMarketItem[itemId].sold;
    require(msg.value == price, "Please submit the asking price in order to complete the purchase");
    require(sold != true, "This Sale has alredy finnished");
    emit MarketItemSold(itemId, msg.sender);

    uint256 itemFee = (msg.value).mul(exchangeFee).div(1000);
    uint256 remainPrice = price - itemFee;
    payable(owner()).transfer(itemFee);
    idToMarketItem[itemId].seller.transfer(remainPrice);
    IERC721Upgradeable(nftContract).transferFrom(address(this), msg.sender, tokenId);
    idToMarketItem[itemId].owner = payable(msg.sender);
    _itemsSold.increment();
    idToMarketItem[itemId].sold = true;
  }

  function fetchMarketItems() public view returns (MarketItem[] memory) {
    uint itemCount = _itemIds.current();
    uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
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

  function handleDelist(address nftContract, uint256 tokenId, uint256 itemId) public payable {
    require((idToMarketItem[itemId].seller == msg.sender || owner() == msg.sender), "Only item owner can delist");

    idToMarketItem[itemId].sold = false;
    idToMarketItem[itemId].seller = payable(address(0));
    idToMarketItem[itemId].owner = payable(msg.sender);
    _itemsSold.increment();
    IERC721Upgradeable(nftContract).transferFrom(address(this), msg.sender, tokenId);
  }

  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

  uint256[49] private __gap;
}