// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Vigilante is Ownable, ERC721A, ReentrancyGuard, VRFConsumerBaseV2 {
  uint256 public immutable maxPerAddressDuringMint;
  uint256 public immutable amountForDevs;
  uint256 public immutable amountForAuctionAndDev;

  string public provenanceHash;
  string public state;

  struct SaleConfig {
    uint32 auctionSaleStartTime;
    uint32 publicSaleStartTime;
    uint64 mintlistPrice;
    uint64 publicPrice;
  }
  SaleConfig public saleConfig;

  mapping(address => uint256) public allowlist;


  // auction variables
  uint256 public AUCTION_START_PRICE = 2 ether;
  uint256 public AUCTION_END_PRICE = 0.1 ether;
  uint256 public AUCTION_PRICE_CURVE_LENGTH = 720 minutes;
  uint256 public AUCTION_DROP_INTERVAL = 20 minutes;
  uint256 public AUCTION_DROP_PER_STEP =
    (AUCTION_START_PRICE - AUCTION_END_PRICE) /
      (AUCTION_PRICE_CURVE_LENGTH / AUCTION_DROP_INTERVAL);

  // ChainLink VRF variables
  address vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
  address link = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
  bytes32 keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;
  uint256 public s_requestId;
  uint256[] public s_randomWords;
  uint64 s_subscriptionId;
  VRFCoordinatorV2Interface COORDINATOR;
  LinkTokenInterface LINKTOKEN;
  uint16 requestConfirmations = 3;
  uint32 numWords = 1;
  uint32 callbackGasLimit = 100000;

  // // metadata URI
  string private _baseTokenURI;

  constructor(
    uint256 maxBatchSize_,
    uint256 collectionSize_,
    uint256 amountForAuctionAndDev_,
    uint256 amountForDevs_,
    uint64 subscriptionId
  ) ERC721A("Vigilante", "Vigilante", maxBatchSize_, collectionSize_) VRFConsumerBaseV2(vrfCoordinator) {
    maxPerAddressDuringMint = 420;
    amountForAuctionAndDev = amountForAuctionAndDev_;
    amountForDevs = amountForDevs_;

    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    LINKTOKEN = LinkTokenInterface(link);
    s_subscriptionId = subscriptionId;

    state = "Minting has not started";
    require(
      amountForAuctionAndDev_ <= collectionSize_,
      "larger collection size needed"
    );
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function setProvenanceHash(string calldata hash) external onlyOwner {
        provenanceHash = hash;
  }

  // ChainLink VRF random number generator Assumes the subscription is funded sufficiently.
  function requestRandomWords() external onlyOwner {
    // Will revert if subscription is not set and funded.

    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
  }

  // ChainLink VRF callback function
  function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory randomWords
  ) internal override {
    s_randomWords.push(randomWords[0]);
  }

  function auctionMint(uint256 quantity) external payable callerIsUser {
    require(
      saleConfig.auctionSaleStartTime != 0 && block.timestamp >= saleConfig.auctionSaleStartTime,
      "sale has not started yet"
    );
    require(
      totalSupply() + quantity <= amountForAuctionAndDev,
      "not enough remaining reserved for auction to support desired mint amount"
    );
    require(
      numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint,
      "can not mint this many"
    );
    uint256 totalCost = getAuctionPrice() * quantity;
    _safeMint(msg.sender, quantity);
    refundIfOver(totalCost);
  }

  function allowlistMint() external payable callerIsUser {
    uint256 price = uint256(saleConfig.mintlistPrice);
    require(price != 0, "allowlist sale has not begun yet");
    require(allowlist[msg.sender] > 0, "not eligible for allowlist mint");
    require(totalSupply() + 1 <= collectionSize, "reached max supply");
    allowlist[msg.sender]--;
    _safeMint(msg.sender, 1);
    refundIfOver(price);
  }

  function publicSaleMint(uint256 quantity)
    external
    payable
    callerIsUser
  {
    SaleConfig memory config = saleConfig;
    uint256 publicPrice = uint256(config.publicPrice);
    uint256 publicSaleStartTime = uint256(config.publicSaleStartTime);

    require(
      isPublicSaleOn(publicPrice, publicSaleStartTime),
      "public sale has not begun yet"
    );
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require(
      numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint,
      "can not mint this many"
    );
    _safeMint(msg.sender, quantity);
    refundIfOver(publicPrice * quantity);
  }

  function refundIfOver(uint256 price) private {
    require(msg.value >= price, "Need to send more ETH.");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }

  function isPublicSaleOn(
    uint256 publicPriceWei,
    uint256 publicSaleStartTime
  ) public view returns (bool) {
    return
      publicPriceWei != 0 &&
      block.timestamp >= publicSaleStartTime;
  }

  function getAuctionPrice()
    public
    view
    returns (uint256){
        if (saleConfig.auctionSaleStartTime == 0 || block.timestamp < saleConfig.auctionSaleStartTime) {
          return AUCTION_START_PRICE;
        }
        if (block.timestamp - saleConfig.auctionSaleStartTime >= AUCTION_PRICE_CURVE_LENGTH) {
          return AUCTION_END_PRICE;
        } else {
          uint256 steps = (block.timestamp - saleConfig.auctionSaleStartTime) /
            AUCTION_DROP_INTERVAL;
          return AUCTION_START_PRICE - (steps * AUCTION_DROP_PER_STEP);
        }
    }

  function startAllowlistMint(uint64 mintlistPriceWei) external onlyOwner{
    saleConfig.mintlistPrice = mintlistPriceWei;
    state = "Allowlist Minting";
  }

  function endAllowlistMintAndStartAuction(uint32 timestamp, uint256 start_priceWEI, uint256 end_priceWEI, uint256 auction_durationSec, uint256 drop_freqSec) external onlyOwner {
    saleConfig.auctionSaleStartTime = timestamp;
    saleConfig.mintlistPrice = 0;
    AUCTION_START_PRICE = start_priceWEI;
    AUCTION_END_PRICE = end_priceWEI;
    AUCTION_PRICE_CURVE_LENGTH = auction_durationSec;
    AUCTION_DROP_INTERVAL = drop_freqSec;
    AUCTION_DROP_PER_STEP =
    (AUCTION_START_PRICE - AUCTION_END_PRICE) /
      (AUCTION_PRICE_CURVE_LENGTH / AUCTION_DROP_INTERVAL);
    state = "Auction Minting";
  }

  function endAuctionAndStartPublicMint(
    uint64 publicPriceWei,
    uint32 publicSaleStartTime
  ) external onlyOwner {
    saleConfig = SaleConfig(
      0,
      publicSaleStartTime,
      0,
      publicPriceWei
    );
    state = "Public Minting";
  }

  function seedAllowlist(address[] memory addresses, uint256[] memory numSlots)
    external
    onlyOwner
  {
    require(
      addresses.length == numSlots.length,
      "addresses do not match numSlots length"
    );
    for (uint256 i = 0; i < addresses.length; i++) {
      allowlist[addresses[i]] = numSlots[i];
    }
  }

  function devMint(uint256 quantity) external onlyOwner {
    require(
      totalSupply() + quantity <= amountForDevs,
      "too many already minted before dev mint"
    );
    uint256 numChunks = quantity / maxBatchSize;
    for (uint256 i = 0; i < numChunks; i++) {
      _safeMint(msg.sender, maxBatchSize);
    }

    if (quantity % maxBatchSize != 0){
      _safeMint(msg.sender, quantity % maxBatchSize);
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
    state = "Metadata Revealed";
  }

  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
    _setOwnersExplicit(quantity);
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
  }
}