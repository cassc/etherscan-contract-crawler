// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

error SaleNotStarted();
error SaleInProgress();
error InsufficientPayment();
error IncorrectPayment();
error AccountNotWhitelisted();
error AmountExceedsSupply();
error AmountExceedsWhitelistLimit();
error AmountExceedsTransactionLimit();
error OnlyExternallyOwnedAccountsAllowed();

contract CerealClub is ERC721A, Ownable, ReentrancyGuard {
  using ECDSA for bytes32;

  uint256 public constant MAX_SUPPLY = 10000;
  uint256 private constant AUCTION_START_PRICE = 0.5 ether;
  uint256 private constant AUCTION_STEP_PRICE = 0.05 ether;
  uint256 private constant AUCTION_STEP_SECONDS = 10 minutes;
  uint256 private constant AUCTION_MIN_PRICE = 0.1 ether;
  uint256 private constant FAR_FUTURE = 0xFFFFFFFFF;
  uint256 private constant MAX_MINTS_PER_TX = 5;

  uint256 private _auctionStart = FAR_FUTURE;
  uint256 private _presaleStart = FAR_FUTURE;
  uint256 private _publicSaleStart = FAR_FUTURE;
  uint256 private _auctionMaxSupply = 7300;
  uint256 private _marketingSupply = 200;
  uint256 private _salePrice = 0.25 ether;

  address private _verifier;
  string private _baseTokenURI;
  mapping(address => bool) private _mintedWhitelist;

  event AuctionStart(uint256 price);
  event PresaleStart(uint256 price, uint256 supplyRemaining);
  event PublicSaleStart(uint256 price, uint256 supplyRemaining);
  event SalePaused();

  constructor(address verifier) ERC721A("CerealClub", "CEREAL") {
    _verifier = verifier;
  }

  // AUCTION

  function isAuctionActive() public view returns (bool) {
    return block.timestamp > _auctionStart;
  }

  function getAuctionPrice() public view returns (uint256) {
    unchecked {
      uint256 steps = (block.timestamp - _auctionStart) / AUCTION_STEP_SECONDS;
      if (steps > FAR_FUTURE) { // overflow if not started
        return AUCTION_START_PRICE;
      }
      uint256 discount = steps * AUCTION_STEP_PRICE;
      if (discount > AUCTION_START_PRICE - AUCTION_MIN_PRICE) {
        return AUCTION_MIN_PRICE;
      }
      return AUCTION_START_PRICE - discount;
    }
  }

  function auctionMint(uint256 quantity) external payable nonReentrant onlyEOA {
    if (!isAuctionActive())                           revert SaleNotStarted();
    if (totalSupply() + quantity > _auctionMaxSupply) revert AmountExceedsSupply();
    if (quantity > MAX_MINTS_PER_TX)                  revert AmountExceedsTransactionLimit();

    uint256 price = getAuctionPrice() * quantity;
    if (msg.value < price) revert InsufficientPayment();

    _safeMint(msg.sender, quantity);

    // Refund overpayment
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }

  // PRESALE WHITELIST

  function isPresaleActive() public view returns (bool) {
    return block.timestamp > _presaleStart;
  }

  function getSalePrice() public view returns (uint256) {
    return _salePrice;
  }

  function presaleMint(bytes calldata sig) external payable nonReentrant onlyEOA {
    if (!isPresaleActive())              revert SaleNotStarted();
    if (!isWhitelisted(msg.sender, sig)) revert AccountNotWhitelisted();
    if (hasMintedPresale(msg.sender))    revert AmountExceedsWhitelistLimit();
    if (totalSupply() + 1 > MAX_SUPPLY)  revert AmountExceedsSupply();
    if (getSalePrice() != msg.value)     revert IncorrectPayment();

    _mintedWhitelist[msg.sender] = true;
    _safeMint(msg.sender, 1);
  }

  function hasMintedPresale(address account) public view returns (bool) {
    return _mintedWhitelist[account];
  }

  function isWhitelisted(address account, bytes calldata sig) internal view returns (bool) {
    return ECDSA.recover(keccak256(abi.encodePacked(account)).toEthSignedMessageHash(), sig) == _verifier;
  }

  // PUBLIC SALE

  function isPublicSaleActive() public view returns (bool) {
    return block.timestamp > _publicSaleStart;
  }

  function publicSaleMint(uint256 quantity) external payable nonReentrant onlyEOA {
    if (!isPublicSaleActive())                  revert SaleNotStarted();
    if (totalSupply() + quantity > MAX_SUPPLY)  revert AmountExceedsSupply();
    if (getSalePrice() * quantity != msg.value) revert IncorrectPayment();
    if (quantity > MAX_MINTS_PER_TX)            revert AmountExceedsTransactionLimit();

    _safeMint(msg.sender, quantity);
  }

  // METADATA

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  // WEBSITE HELPERS

  struct MintSummary {
    bool isAuctionActive; bool isPresaleActive; bool isPublicSaleActive;
    uint256 auctionPrice; uint256 salePrice; uint256 blockTime;
    uint256 maxSupply; uint256 totalSupply; uint256 auctionSupply;
    uint256 priceAfterNextAuctionPriceDrop; uint256 secondsUntilNextAuctionPriceDrop;
  }

  function getMintSummary() external view returns (MintSummary memory summary) {
    bool auctionActive = isAuctionActive();
    uint256 autionPrice = getAuctionPrice();

    // Compute next drop
    uint256 secondsUntilNextAuctionPriceDrop;
    uint256 priceAfterNextAuctionPriceDrop;
    if (auctionActive && autionPrice > AUCTION_MIN_PRICE) {
      uint256 elapsedSeconds = block.timestamp - _auctionStart;
      uint256 nextSteps = (elapsedSeconds / AUCTION_STEP_SECONDS) + 1;
      uint256 nextDiscount = nextSteps * AUCTION_STEP_PRICE;
      secondsUntilNextAuctionPriceDrop = AUCTION_STEP_SECONDS - (elapsedSeconds % AUCTION_STEP_SECONDS);
      priceAfterNextAuctionPriceDrop = AUCTION_START_PRICE - nextDiscount;
    }

    summary = MintSummary({
      isAuctionActive: auctionActive,
      isPresaleActive: isPresaleActive(),
      isPublicSaleActive: isPublicSaleActive(),
      auctionPrice: autionPrice,
      salePrice: getSalePrice(),
      maxSupply: MAX_SUPPLY,
      totalSupply: totalSupply(),
      auctionSupply: _auctionMaxSupply,
      priceAfterNextAuctionPriceDrop: priceAfterNextAuctionPriceDrop,
      secondsUntilNextAuctionPriceDrop: secondsUntilNextAuctionPriceDrop,
      blockTime: block.timestamp
    });
  }

  function tokensOf(address owner) public view returns (uint256[] memory){
    uint256 count = balanceOf(owner);
    uint256[] memory tokenIds = new uint256[](count);
    for (uint256 i; i < count; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(owner, i);
    }
    return tokenIds;
  }

  // OWNERS + HELPERS

  function setAuctionMaxSupply(uint256 auctionMaxSupply) external onlyOwner {
    if (_marketingSupply + auctionMaxSupply > MAX_SUPPLY)
      revert AmountExceedsSupply();

    _auctionMaxSupply = auctionMaxSupply;
  }

  function startAuction() external onlyOwner {
    if (isPresaleActive() || isPublicSaleActive()) revert SaleInProgress();

    _auctionStart = block.timestamp;

    emit AuctionStart(getAuctionPrice());
  }

  function startPresale(uint256 price) external onlyOwner {
    if (isAuctionActive() || isPublicSaleActive()) revert SaleInProgress();

    _presaleStart = block.timestamp;
    _salePrice = price;

    emit PresaleStart(price, MAX_SUPPLY - totalSupply());
  }

  function startPublicSale() external onlyOwner {
    if (isAuctionActive() || isPresaleActive()) revert SaleInProgress();

    _publicSaleStart = block.timestamp;

    emit PublicSaleStart(getSalePrice(), MAX_SUPPLY - totalSupply());
  }

  function pauseSale() external onlyOwner {
    _auctionStart = FAR_FUTURE;
    _presaleStart = FAR_FUTURE;
    _publicSaleStart = FAR_FUTURE;

    emit SalePaused();
  }

  modifier onlyEOA() {
    if (tx.origin != msg.sender) revert OnlyExternallyOwnedAccountsAllowed();
    _;
  }

  function setSalePrice(uint256 price) external onlyOwner {
    _salePrice = price;
  }

  // Team/Partnerships & Community
  function marketingMint(uint256 quantity) external onlyOwner {
    if (quantity > _marketingSupply) revert AmountExceedsSupply();
    if (totalSupply() + quantity > MAX_SUPPLY) revert AmountExceedsSupply();

    _marketingSupply -= quantity;
    _safeMint(owner(), quantity);
  }

  function withdraw() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }
}