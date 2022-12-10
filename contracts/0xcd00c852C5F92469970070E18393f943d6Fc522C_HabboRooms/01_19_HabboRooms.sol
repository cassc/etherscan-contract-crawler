// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";

import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract HabboRooms is ERC721ABurnable, ERC2981, Ownable, AccessControl, DefaultOperatorFilterer {
  using ECDSA for bytes32;
  using Strings for uint256;

  error EndTimeIsInThePast();
  error StartTimeIsHigherThanEndTime();
  error PriceShouldBeSameOrLower();
  error IntervalCanNotBeZero();
  error TotalCanNotBeZero();
  error PurchaseLimitCanNotBeZero();
  error OrderLimitCanNotBeZero();
  error GroupKeyCanNotBeEmpty();
  error RoomKeyCanNotBeEmpty();
  error InvalidSignature();
  error InvalidListingId();
  error ListingNotStarted();
  error ListingHasFinished();
  error InvalidEthAmount();
  error ExceededPurchaseLimit();
  error ExceededListingPurchaseLimit();
  error ExceededMintLimit();
  error ExceededOrderLimit();
  error OrderLimitOverPurchaseListingLimit();
  error PurchaseLimitOverTotalMintLimit();
  error PurchaseListingLimitCanNotBeZero();
  error ListingMarkedInvalid();
  error ListingGroupMarkedInvalid();
  error QuantityCanNotBeZero();

  // File extension for metadata file
  string private constant _EXTENSION = ".json";

  // Role for signature minters
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  // The base domain for the tokenURI
  string private _baseTokenURI;
  
  event RoomMinted(uint startTokenId, uint endTokenId, string roomKey);

  struct ListingGroup {
    uint totalMintLimit; // total amount of mints in this group
    uint totalMinted;
    uint purchaseLimit; // total amount one can purchase in a group of sales
    bool valid; // if wrong information was inputted we can mark listing group invalid
  }
  
  mapping(string => ListingGroup) public listingGroups;
  
  struct Listing { 
    string roomKey;
    string groupKey;
    uint startTime;
    uint endTime;
    uint startPrice;
    uint finalPrice;
    uint intervals; // steps between start and final price
    uint purchaseListingLimit; // total amount one can purchase from this sale
    uint orderLimit; // total amount one can purchase every transaction
    bool valid; // if wrong information was inputted we can mark listing invalid
  }
  
  Listing[] public listings;

  function listingsLength() public view returns(uint count) {
    return listings.length;
  }

  mapping(string => mapping(address => uint)) public purchasedAmounts;
  mapping(uint => mapping(address => uint)) public listingPurchasedAmounts;

  constructor(string memory baseURI, address mintSigner) 
    ERC721A("Habbo Rooms", "HABXROOM") 
    Ownable()
  {
    setBaseURI(baseURI);
    setRoyaltyInfo(payable(owner()), 500);

    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(MINTER_ROLE, mintSigner);
  }

  function createListingGroup(
    string calldata groupKey,
    uint totalMintLimit,
    uint purchaseLimit
  ) external onlyOwner returns (ListingGroup memory lg) {
    if (bytes(groupKey).length <= 0) revert GroupKeyCanNotBeEmpty();
    if (totalMintLimit <= 0) revert TotalCanNotBeZero();
    if (purchaseLimit <= 0) revert PurchaseLimitCanNotBeZero();
    if (purchaseLimit > totalMintLimit) revert PurchaseLimitOverTotalMintLimit();

    lg = ListingGroup({
      totalMintLimit: totalMintLimit,
      totalMinted: 0,
      purchaseLimit: purchaseLimit,
      valid: true
    });

    listingGroups[groupKey] = lg;
  }

  function addListing(
    string calldata roomKey,
    string calldata groupKey,
    uint startTime,
    uint endTime,
    uint startPrice,
    uint finalPrice,
    uint intervals,
    uint purchaseListingLimit,
    uint orderLimit
  ) external onlyOwner returns (Listing memory l, uint listingId) {
    if (bytes(roomKey).length <= 0) revert RoomKeyCanNotBeEmpty();
    if (bytes(groupKey).length <= 0) revert GroupKeyCanNotBeEmpty();
    if (block.timestamp >= endTime) revert EndTimeIsInThePast();
    if (startTime >= endTime) revert StartTimeIsHigherThanEndTime();
    if (finalPrice > startPrice) revert PriceShouldBeSameOrLower();
    if (intervals <= 0) revert IntervalCanNotBeZero();
    if (purchaseListingLimit <= 0) revert PurchaseListingLimitCanNotBeZero();
    if (orderLimit <= 0) revert OrderLimitCanNotBeZero();
    if (orderLimit > purchaseListingLimit) revert OrderLimitOverPurchaseListingLimit();

    
    l = Listing({
      roomKey: roomKey,
      groupKey: groupKey,
      startTime: startTime,
      endTime: endTime,
      startPrice: startPrice,
      finalPrice: finalPrice,
      intervals: intervals,
      purchaseListingLimit: purchaseListingLimit,
      orderLimit: orderLimit,
      valid: true
    });

    listings.push(l);

    listingId = listings.length - 1;
  }

  function markListingInvalid(uint listingId) external onlyOwner {
    if (listingId >= listings.length || !listings[listingId].valid) revert InvalidListingId();

    Listing storage l = listings[listingId];

    l.valid = false;
  }

  function markListingGroupInvalid(string memory groupKey) external onlyOwner {
    ListingGroup storage lg = listingGroups[groupKey];
    
    if (!lg.valid) revert InvalidListingId();

    lg.valid = false;
  }

  function mint(uint quantity, uint listingId, bytes calldata signature) external payable {
    if (quantity <= 0) revert QuantityCanNotBeZero();
    if (!verifySignature(signature, getTransactionHash(msg.sender, listingId))) revert InvalidSignature();
    if (listingId >= listings.length) revert InvalidListingId();

    Listing storage l = listings[listingId];

    if (!l.valid) revert ListingMarkedInvalid();
    
    ListingGroup storage lg = listingGroups[l.groupKey];

    if (!lg.valid) revert ListingGroupMarkedInvalid();
    
    if (block.timestamp < l.startTime) revert ListingNotStarted();
    if (block.timestamp > l.endTime) revert ListingHasFinished();

    uint currentPrice = getPriceByListing(l) * quantity;

    if (msg.value < currentPrice) revert InvalidEthAmount();

    if (quantity > l.orderLimit) revert ExceededOrderLimit();
    if (listingPurchasedAmounts[listingId][msg.sender] + quantity > l.purchaseListingLimit) revert ExceededListingPurchaseLimit();
    if (purchasedAmounts[l.groupKey][msg.sender] + quantity > lg.purchaseLimit) revert ExceededPurchaseLimit();
    if (lg.totalMinted + quantity > lg.totalMintLimit) revert ExceededMintLimit();
    
    purchasedAmounts[l.groupKey][msg.sender] += quantity;
    listingPurchasedAmounts[listingId][msg.sender] += quantity;
    lg.totalMinted += quantity;

    mintTokens(quantity, msg.sender, l.roomKey);
  }

  function ownerMint(uint quantity, address to, string calldata roomKey) external onlyOwner {
    mintTokens(quantity, to, roomKey);
  }

  function withdrawFunds() external onlyOwner {
    uint balance = address(this).balance;
    (bool success,) = payable(msg.sender).call{value: balance}("");
    require(success, "WITHDRAWAL_FAILED");
  }

  function mintTokens(uint quantity, address to, string memory roomKey) private {
    uint startTokenId = _nextTokenId();
    uint endTokenId = startTokenId + quantity - 1;

    _safeMint(to, quantity);

    emit RoomMinted(startTokenId, endTokenId, roomKey);
  }

  function getPriceByListingAtTimestamp(Listing memory l, uint timestamp) public view onlyOwner returns (uint) {
    return _getPriceByListingAtTimestamp(l, timestamp);
  }

  function getPriceByListing(Listing memory l) public view returns (uint) {
    return _getPriceByListingAtTimestamp(l, block.timestamp);
  }

  function getPriceByListingIdAtTimestamp(uint index, uint timestamp) public view onlyOwner returns (uint) {
    return _getPriceByListingAtTimestamp(listings[index], timestamp);
  }

  function getPriceByListingId(uint index) public view returns (uint) {
    return _getPriceByListingAtTimestamp(listings[index], block.timestamp);
  }

  function _getPriceByListingAtTimestamp(Listing memory l, uint timestamp) private pure returns (uint) {
    if (l.startTime >= timestamp) {
      return l.startPrice;
    }

    if (timestamp >= l.endTime) {
      return l.finalPrice;
    }
    
    uint timeInterval = (l.endTime - l.startTime) / l.intervals;
    uint priceInterval = (l.startPrice - l.finalPrice) / l.intervals;

    uint intervalsComplete = (timestamp - l.startTime) / timeInterval;

    return l.startPrice - intervalsComplete * priceInterval;
  }

  function setRoyaltyInfo(address payable receiver, uint96 numerator) public onlyOwner {
    _setDefaultRoyalty(receiver, numerator);
  }

  function tokenURI(uint256 tokenId) public view override (ERC721A, IERC721A) returns (string memory) {
    return string(abi.encodePacked(_baseURI(), tokenId.toString(), _EXTENSION));
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    _baseTokenURI = baseURI;
  }

  function _startTokenId() internal override pure returns (uint256) {
    return 1;
  }

  function getTransactionHash(address to, uint listingId) public view returns (bytes32) {
    return keccak256(abi.encodePacked(address(this), to, listingId));
  }

  function verifySignature(bytes memory signature, bytes32 transactionHash) private view returns (bool) {
    address signer = transactionHash.toEthSignedMessageHash().recover(signature);
    return owner() == signer || hasRole(MINTER_ROLE, signer);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC721A, ERC2981, AccessControl) returns (bool) {
    return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
  }

  /*
    OPERATOR FILTERER overrides
  */

  function setApprovalForAll(address operator, bool approved) public override (ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public payable override (ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public payable override (ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public payable override (ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public 
    payable
    override (ERC721A, IERC721A)
    onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}