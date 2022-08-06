// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "erc721a/contracts/ERC721A.sol";

contract MogiesDutchAuction is Ownable, ERC721A, ReentrancyGuard {
  using Strings for uint256;
  using SafeERC20 for IERC20;
  IERC20 stars;

  uint256 public immutable maxBatchSize;
  uint256 public immutable amountForDevs = 50;
  uint256 public immutable amountForSales = 1073;
  uint256 public immutable amountForAuction = 800;
  uint256 public immutable totalAmount = 1923;

  // prices in usd
  uint256 public ethUSDPrice;
  uint256 public starsUSDPrice;

  string private _name;
  string private _symbol;

  // dates for auction
  uint256 public constant AUCTION_PRICE_CURVE_LENGTH = 5 days;
  uint256 public constant AUCTION_DROP_INTERVAL = 1 days;
  uint256 usersBonusNotMinted = 0;
  uint256 usersBonusMinted = 0;
  uint256 totalRebateAmount = 0;

  bytes32 public allowListMerkleRoot;

  struct SaleConfig {
    uint32 auctionSaleStartTime;
    uint32 auctionSaleEndTime;
    uint32 whitelistSaleStartTime;
    uint32 whitelistSaleEndTime;
    uint32 publicSaleStartTime;
    uint32 publicSaleEndTime;
    uint32 devMintedAmount;
    uint32 auctionMintedAmount;
    uint32 saleMintedAmount;
    // for final price after auction sells out, should be used for mintListPrice and publicPrice
    uint256 ethPrice;
    uint256 starsPrice;
    bool hasPublicSale;
  }

  struct Sale {
    uint8 quantity;
    uint32 tier;
    uint256 pricePaid;
    bool isStars;
  }

  // sales for each wallet
  mapping(uint256 => address[]) public buyerList;
  mapping(address => Sale[]) public sales;
  mapping(address => bool) public hasClaimedRebate;

  // remaining mint amount
  // keeps track of order tier1 buyers bought
  mapping(address => uint256) public remainingMintAmount;

  // singleton variable for sale
  SaleConfig public saleConfig =
    SaleConfig({
      auctionSaleStartTime: 0,
      auctionSaleEndTime: 0,
      whitelistSaleStartTime: 0,
      whitelistSaleEndTime: 0,
      publicSaleStartTime: 0,
      publicSaleEndTime: 0,
      devMintedAmount: 0,
      auctionMintedAmount: 0,
      saleMintedAmount: 0,
      ethPrice: 1 ether,
      starsPrice: 74862 ether,
      hasPublicSale: false
    });

  event Purchase(
    address wallet,
    uint32 quantity,
    bool isUsingStars,
    uint256 starsPrice,
    uint256 ethPrice
  );

  constructor(
    IERC20 _stars,
    address _owner,
    uint256 _maxBatchSize,
    uint256 _ethUSDPrice, // Price to lock these at beginning (used for rebate)
    uint256 _starsUSDPrice, // Price to lock these at beginning (used for rebate)
    // start and end times for auction and sales
    uint32 _auctionSaleStartTime,
    uint32 _auctionSaleEndTime,
    uint32 _whitelistSaleStartTime,
    uint32 _whitelistSaleEndTime,
    uint32 _publicSaleStartTime,
    uint32 _publicSaleEndTime
  ) ERC721A("Mogies", "MOGIES") {
    transferOwnership(_owner);
    maxBatchSize = _maxBatchSize;
    stars = _stars;

    ethUSDPrice = _ethUSDPrice;
    starsUSDPrice = _starsUSDPrice;

    _name = "Mogies";
    _symbol = "MOGIES";

    saleConfig.auctionSaleStartTime = _auctionSaleStartTime;
    saleConfig.auctionSaleEndTime = _auctionSaleEndTime;
    saleConfig.whitelistSaleStartTime = _whitelistSaleStartTime;
    saleConfig.whitelistSaleEndTime = _whitelistSaleEndTime;
    saleConfig.publicSaleStartTime = _publicSaleStartTime;
    saleConfig.publicSaleEndTime = _publicSaleEndTime;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  modifier auctionAndSalesEnded() {
    require(
      block.timestamp > saleConfig.publicSaleEndTime &&
        block.timestamp > saleConfig.whitelistSaleEndTime &&
        block.timestamp >
        saleConfig.auctionSaleStartTime + AUCTION_PRICE_CURVE_LENGTH,
      "too early"
    );
    _;
  }

  modifier isBeforeAuctionStarts() {
    require(
      block.timestamp < saleConfig.auctionSaleStartTime,
      "sale has already started"
    );
    _;
  }

  // For marketing etc.
  // MUST BE MINTED BEFORE AUCTION AND SALES
  function devMint(uint32 quantity, address recipient) external onlyOwner {
    require(
      saleConfig.devMintedAmount + quantity <= amountForDevs,
      "too many already minted before dev mint"
    );
    saleConfig.devMintedAmount += quantity;
    _batchMint(recipient, quantity);
  }

  function earlyMint(uint32 quantity, address recipient)
    external
    onlyOwner
    isBeforeAuctionStarts
  {
    require(
      saleConfig.auctionMintedAmount + quantity <= amountForAuction,
      "too many already minted before early mint"
    );
    saleConfig.auctionMintedAmount += quantity;
    _batchMint(recipient, quantity);
  }

  // Function to handle dutch auction
  function auctionMint(uint32 quantity, bool isUsingStars)
    external
    payable
    callerIsUser
  {
    uint256 _auctionStartTime = uint256(saleConfig.auctionSaleStartTime);
    require(
      _auctionStartTime <= block.timestamp &&
        block.timestamp < saleConfig.auctionSaleEndTime,
      "sale has not started yet"
    );
    require(
      saleConfig.auctionMintedAmount + quantity <= amountForAuction,
      "Purchase would exceed max supply for Dutch auction mint"
    );
    uint256 auctionPrice = getAuctionPrice(_auctionStartTime, isUsingStars);
    uint256 otherAuctionPrice = getAuctionPrice(
      _auctionStartTime,
      !isUsingStars
    );
    uint256 totalCost = auctionPrice * quantity;

    // Keep track of how amount paid during auction
    uint256 totalPaid;

    if (isUsingStars) {
      saleConfig.starsPrice = auctionPrice;
      saleConfig.ethPrice = otherAuctionPrice;
      totalPaid = totalCost;
      stars.safeTransferFrom(msg.sender, address(this), totalPaid);
    } else {
      saleConfig.ethPrice = auctionPrice;
      saleConfig.starsPrice = otherAuctionPrice;
      totalPaid = msg.value - refundIfOver(totalCost);
    }
    saleConfig.auctionMintedAmount += quantity;
    _batchMint(msg.sender, quantity);
    uint256 tier = (block.timestamp - _auctionStartTime) /
      AUCTION_DROP_INTERVAL;
    buyerList[tier].push(msg.sender);

    if (remainingMintAmount[msg.sender] == 0) {
      usersBonusNotMinted++;
      remainingMintAmount[msg.sender] = usersBonusNotMinted;
    }

    sales[msg.sender].push(
      Sale({
        quantity: uint8(quantity),
        pricePaid: totalPaid,
        tier: uint32(tier),
        isStars: isUsingStars
      })
    );

    emit Purchase(
      msg.sender,
      quantity,
      isUsingStars,
      saleConfig.starsPrice,
      saleConfig.ethPrice
    );
  }

  // merkle tree will be updated during whitelist sale
  // Function to handle white list sale
  function allowlistMint(
    uint32 quantity,
    bool isUsingStars,
    bytes32[] calldata _proof
  ) external payable callerIsUser {
    require(
      saleConfig.saleMintedAmount + quantity <= amountForSales,
      "Purchase would exceed max supply for allowlistMint"
    );
    require(
      isAllowListed(_proof, msg.sender),
      "This address is not allow listed for the presale"
    );
    require(
      saleConfig.whitelistSaleStartTime < block.timestamp &&
        block.timestamp < saleConfig.whitelistSaleEndTime,
      "outside of allowlist sale times"
    );

    if (isUsingStars) {
      stars.safeTransferFrom(
        msg.sender,
        address(this),
        saleConfig.starsPrice * quantity
      );
    } else {
      refundIfOver(saleConfig.ethPrice * quantity);
    }
    saleConfig.saleMintedAmount += quantity;
    _batchMint(msg.sender, quantity);

    emit Purchase(
      msg.sender,
      quantity,
      isUsingStars,
      saleConfig.starsPrice,
      saleConfig.ethPrice
    );
  }

  function isAllowListed(bytes32[] calldata _proof, address _address)
    public
    view
    returns (bool)
  {
    require(_address != address(0), "Zero address not on Allow List");

    bytes32 leaf = keccak256(abi.encodePacked(_address));
    return MerkleProof.verify(_proof, allowListMerkleRoot, leaf);
  }

  // merkle tree will be updated during whitelist sale
  function setAllowListMerkleRoot(bytes32 _allowListMerkleRoot)
    external
    onlyOwner
  {
    allowListMerkleRoot = _allowListMerkleRoot;
  }

  // Function to handle public sale
  function publicSaleMint(uint32 quantity, bool isUsingStars)
    external
    payable
    callerIsUser
  {
    require(
      amountForDevs + saleConfig.saleMintedAmount + saleConfig.auctionMintedAmount + quantity <=
        totalAmount,
      "Purchase would exceed max supply"
    );
    require(saleConfig.publicSaleStartTime < block.timestamp && block.timestamp < saleConfig.publicSaleEndTime, "public sale not active");
    require(isPublicSaleOn(), "public sale is not active");
    saleConfig.saleMintedAmount += quantity;
    if (isUsingStars) {
      stars.safeTransferFrom(
        msg.sender,
        address(this),
        saleConfig.starsPrice * quantity
      );
    } else {
      refundIfOver(saleConfig.ethPrice * quantity);
    }
    _batchMint(msg.sender, quantity);

    emit Purchase(
      msg.sender,
      quantity,
      isUsingStars,
      saleConfig.starsPrice,
      saleConfig.ethPrice
    );
  }

  function rebate() external auctionAndSalesEnded {
    require(sales[msg.sender].length > 0, "Nothing to rebate.");
    require(!hasClaimedRebate[msg.sender], "Rebate already claimed");
    uint256 rebateAmount = 0;
    // for each sale user made during auction
    for (uint256 i = 0; i < sales[msg.sender].length; i++) {
      uint256 quantity = sales[msg.sender][i].quantity;
      // stars purchase all 1x rebate
      if (sales[msg.sender][i].isStars) {
        rebateAmount += (sales[msg.sender][i].pricePaid -
          (saleConfig.starsPrice * quantity));
      } else {
        //  if in first tier, 1.5x stars rebate
        if (sales[msg.sender][i].tier == 0) {
          rebateAmount +=
            (15000 *
              ((sales[msg.sender][i].pricePaid -
                (saleConfig.ethPrice * quantity)) * ethUSDPrice)) /
            (10000 * starsUSDPrice);
          //if in second tier, 1.3x stars rebate
        } else if (sales[msg.sender][i].tier == 1) {
          rebateAmount +=
            (13000 *
              ((sales[msg.sender][i].pricePaid -
                (saleConfig.ethPrice * quantity)) * ethUSDPrice)) /
            (10000 * starsUSDPrice);
          //if in third tier, 1x stars rebate
        } else if (sales[msg.sender][i].tier == 2) {
          rebateAmount +=
            ((sales[msg.sender][i].pricePaid -
              (saleConfig.ethPrice * quantity)) * ethUSDPrice) /
            starsUSDPrice;
        }
      }
    }

    require(rebateAmount > 0, "Nothing to rebate.");
    hasClaimedRebate[msg.sender] = true;
    stars.safeTransfer(msg.sender, rebateAmount);
  }

  // let dutch auction buyers mint entitled number of mogies
  function mintRemaining() external callerIsUser auctionAndSalesEnded {
    require(totalSupply() < totalAmount, "nothing to mint");
    require(remainingMintAmount[msg.sender] != 0, "cannot mint more");

    uint256 quantity;

    // first time setter for leftover mogies
    if (totalRebateAmount == 0) {
      totalRebateAmount = totalAmount - totalSupply();
    }

    // get base amount to mint per valid user
    if (usersBonusNotMinted + usersBonusMinted == totalRebateAmount) {
      quantity = 1;
    } else if (usersBonusNotMinted + usersBonusMinted < totalRebateAmount) {
      quantity = totalRebateAmount / (usersBonusNotMinted + usersBonusMinted);
    }

    // add one for earlier buyers for extra mogies
    if (
      remainingMintAmount[msg.sender] <=
      // initial total mint remaining amount % total number of users to mint
      totalRebateAmount % (usersBonusNotMinted + usersBonusMinted)
    ) {
      quantity++;
    }

    usersBonusNotMinted--;
    usersBonusMinted++;
    remainingMintAmount[msg.sender] = 0;
    require(quantity > 0, "not entitled to mint remaining");
    _batchMint(msg.sender, quantity);
  }

  function adminFinalMint(address recipient)
    external
    onlyOwner
    auctionAndSalesEnded
  {
    require(totalSupply() < totalAmount, "nothing to mint");
    _batchMint(recipient, totalAmount - totalSupply());
  }

  function isPublicSaleOn() public view returns (bool) {
    return
      saleConfig.hasPublicSale &&
      saleConfig.publicSaleStartTime <= block.timestamp &&
      block.timestamp < saleConfig.publicSaleEndTime;
  }

  function setPublicSale(bool _publicSale) external onlyOwner {
    saleConfig.hasPublicSale = _publicSale;
  }

  // ETH prices for auction
  uint256 public AUCTION_START_ETH_PRICE = 1 ether;
  uint256 public AUCTION_END_ETH_PRICE = 200000000 gwei; //0.2 eth
  uint256 public AUCTION_DROP_PER_STEP_ETH = 200000000 gwei; //0.2 eth

  uint256 public AUCTION_START_STARS_PRICE = 74862 ether;
  uint256 public AUCTION_END_STARS_PRICE = 14972400000000 gwei; // 14,972.4 eth
  uint256 public AUCTION_DROP_PER_STEP_STARS = 14972400000000 gwei; // 14,972.4 eth

  // helper functions for setting prices right before auction
  // NOTE: Only for when huge price discrepencies from time of deploying contract to start of auction. Will not be available once auction has already started.
  function setAuctionEthParams(
    uint256 _auctionStartEthPrice,
    uint256 _auctionEndEthPrice,
    uint256 _auctionDropPerStepEth
  ) external onlyOwner isBeforeAuctionStarts {
    AUCTION_START_ETH_PRICE = _auctionStartEthPrice;
    AUCTION_END_ETH_PRICE = _auctionEndEthPrice;
    AUCTION_DROP_PER_STEP_ETH = _auctionDropPerStepEth;
  }

  function setAuctionStarsParams(
    uint256 _auctionStartStarsPrice,
    uint256 _auctionEndStarsPrice,
    uint256 _auctionDropPerStepStars
  ) external onlyOwner isBeforeAuctionStarts {
    AUCTION_START_STARS_PRICE = _auctionStartStarsPrice;
    AUCTION_END_STARS_PRICE = _auctionEndStarsPrice;
    AUCTION_DROP_PER_STEP_STARS = _auctionDropPerStepStars;
  }

  function getAuctionPrice(uint256 _saleStartTime, bool _isUsingStars)
    public
    view
    returns (uint256)
  {
    if (_isUsingStars) {
      if (block.timestamp < _saleStartTime) {
        return AUCTION_START_STARS_PRICE;
      }
      if (block.timestamp >= _saleStartTime + AUCTION_PRICE_CURVE_LENGTH) {
        return AUCTION_END_STARS_PRICE;
      } else {
        uint256 steps = (block.timestamp - _saleStartTime) /
          AUCTION_DROP_INTERVAL;
        return
          AUCTION_START_STARS_PRICE - (steps * AUCTION_DROP_PER_STEP_STARS);
      }
    } else {
      if (block.timestamp < _saleStartTime) {
        return AUCTION_START_ETH_PRICE;
      }
      if (block.timestamp >= _saleStartTime + AUCTION_PRICE_CURVE_LENGTH) {
        return AUCTION_END_ETH_PRICE;
      } else {
        uint256 steps = (block.timestamp - _saleStartTime) /
          AUCTION_DROP_INTERVAL;
        return AUCTION_START_ETH_PRICE - (steps * AUCTION_DROP_PER_STEP_ETH);
      }
    }
  }

  function refundIfOver(uint256 price) private returns (uint256) {
    require(msg.value >= price, "Need to send more ETH.");
    uint256 refundAmount = 0;
    if (msg.value > price) {
      refundAmount = msg.value - price;
      payable(msg.sender).transfer(refundAmount);
    }
    return refundAmount;
  }

  function getBuyerList(uint256 tier) external view returns (address[] memory) {
    return buyerList[tier];
  }

  // helper functions for setting prices right before auction
  // NOTE: Only for when huge price discrepencies from time of deploying contract to start of auction. Will not be available once auction has already started.
  function setEthUsdPrice(uint256 _ethUsdPrice)
    external
    onlyOwner
    isBeforeAuctionStarts
  {
    ethUSDPrice = _ethUsdPrice;
  }

  function setStarsUsdPrice(uint256 _starsUsdPrice)
    external
    onlyOwner
    isBeforeAuctionStarts
  {
    starsUSDPrice = _starsUsdPrice;
  }

  // helper functions for sale times
  function setAuctionSaleStartTime(uint32 timestamp) external onlyOwner {
    saleConfig.auctionSaleStartTime = timestamp;
  }

  function setAuctionSaleEndTime(uint32 timestamp) external onlyOwner {
    saleConfig.auctionSaleEndTime = timestamp;
  }

  function setWhitelistSaleStartTime(uint32 timestamp) external onlyOwner {
    saleConfig.whitelistSaleStartTime = timestamp;
  }

  function setWhitelistSaleEndTime(uint32 timestamp) external onlyOwner {
    saleConfig.whitelistSaleEndTime = timestamp;
  }

  function setPublicSaleStartTime(uint32 timestamp) external onlyOwner {
    saleConfig.publicSaleStartTime = timestamp;
  }

  function setPublicSaleEndTime(uint32 timestamp) external onlyOwner {
    saleConfig.publicSaleEndTime = timestamp;
  }

  function batchSetTimes(uint32 _auctionSaleStartTime, uint32 _auctionSaleEndTime, uint32 _whitelistSaleStartTime, uint32 _whitelistSaleEndTime, uint32 _publicSaleStartTime, uint32 _publicSaleEndTime) external onlyOwner {
    require(_auctionSaleStartTime < _auctionSaleEndTime, "Auction timestamps inverted");
    require(_auctionSaleEndTime < _whitelistSaleStartTime, "Auction before whitelist sale");
    require(_whitelistSaleStartTime < _whitelistSaleEndTime, "Whitelist sale timestamps inverted");
    require(_whitelistSaleEndTime < _publicSaleStartTime, "Whitelist sale before public sale");
    require(_publicSaleStartTime < _publicSaleEndTime, "Public sale timestamps inverted");

    saleConfig.auctionSaleStartTime = _auctionSaleStartTime;
    saleConfig.auctionSaleEndTime = _auctionSaleEndTime;
    saleConfig.whitelistSaleStartTime = _whitelistSaleStartTime;
    saleConfig.whitelistSaleEndTime = _whitelistSaleEndTime;
    saleConfig.publicSaleStartTime = _publicSaleStartTime;
    saleConfig.publicSaleEndTime = _publicSaleEndTime;
  }

  // metadata URI
  string public uriPrefix;
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;

  bool public revealed;

  function setUriPrefix(string calldata _uriPrefix) external onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string calldata _uriSuffix) external onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setRevealed(bool _state) external onlyOwner {
    revealed = _state;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return
      bytes(currentBaseURI).length > 0
        ? string(
          abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix)
        )
        : "";
  }

  function setHiddenMetadataUri(string calldata _hiddenMetadataUri)
    external
    onlyOwner
  {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function withdrawMoney() external onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{ value: address(this).balance }("");
    require(os, "withdraw: transfer failed");

    stars.safeTransfer(owner(), stars.balanceOf(address(this)));
  }

  function _batchMint(address recipient, uint256 quantity) private {
    uint256 numChunks = quantity / maxBatchSize;
    for (uint256 i = 0; i < numChunks; i++) {
      _safeMint(recipient, maxBatchSize);
    }
    uint256 remainder = quantity % maxBatchSize;
    if (remainder != 0) {
      _safeMint(recipient, remainder);
    }
  }

  function name() public view virtual override returns (string memory) {
      return _name;
  }

  function symbol() public view virtual override returns (string memory) {
      return _symbol;
  }
}