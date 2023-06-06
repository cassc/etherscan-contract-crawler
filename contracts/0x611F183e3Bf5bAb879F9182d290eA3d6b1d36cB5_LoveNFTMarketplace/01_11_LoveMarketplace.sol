// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import './LoveRoles.sol';

/* Love NFT Marketplace
    List NFT,
    Buy NFT,
    Offer NFT,
    Accept offer,
    Create auction,
    Bid place,
    & support Royalty
*/
contract LoveNFTMarketplace is LoveRoles, ReentrancyGuard {
  uint256 public platformFee = 50;
  uint256 public platformListingFee = 1 ether;
  uint256 public constant MINIMUM_BUYING_FEE = 5 ether;
  IERC20 private loveToken;
  address private feeReceiver;
  uint256 public reservedBalance;

  constructor(address _loveToken, address tokenOwner) {
    transferOwnership(tokenOwner);
    loveToken = IERC20(_loveToken);
  }

  struct NFT {
    address addr;
    uint256 tokenId;
  }

  struct ListingParams {
    NFT nft;
    uint256 price;
    uint256 startTime;
    uint256 endTime;
  }

  struct ListNFT {
    NFT nft;
    address seller;
    uint256 price;
    uint256 startTime;
    uint256 endTime;
  }

  struct OfferNFT {
    NFT nft;
    address offerer;
    uint256 offerPrice;
    TokenRoyaltyInfo royaltyInfo;
    bool accepted;
  }

  struct OfferNFTParams {
    NFT nft;
    address offerer;
    uint256 price;
  }

  struct AuctionParams {
    NFT nft;
    uint256 initialPrice;
    uint256 minBidStep;
    uint256 startTime;
    uint256 endTime;
  }

  struct AuctionNFT {
    NFT nft;
    address creator;
    uint256 initialPrice;
    uint256 minBidStep;
    uint256 startTime;
    uint256 endTime;
    address lastBidder;
    uint256 highestBid;
    TokenRoyaltyInfo royaltyInfo;
    address winner;
    bool success;
  }

  struct TokenRoyaltyInfo {
    address royaltyReceiver;
    uint256 royaltyAmount;
  }

  // NFT => list struct
  mapping(bytes => ListNFT) private listNfts;

  // NFT => offerer address => offer price => offer struct
  mapping(bytes => mapping(address => mapping(uint256 => OfferNFT))) private offerNfts;

  // NFT => action struct
  mapping(bytes => AuctionNFT) private auctionNfts;

  // events
  event ChangedPlatformFee(uint256 newValue);
  event RewardSent(address[] addresses, uint[] amounts);
  event ChangedFeeReceiver(address newFeeReceiver);

  event ListedNFT(
    address indexed nftAddress,
    uint256 indexed tokenId,
    uint256 price,
    address indexed seller,
    uint256 startTime,
    uint256 endTime
  );

  event UpdateListedNFT(
    address indexed nftAddress,
    uint256 indexed tokenId,
    uint256 price,
    uint256 startTime,
    uint256 endTime
  );

  event CanceledListedNFT(
    address indexed nftAddress,
    uint256 indexed tokenId,
    uint256 price,
    address indexed seller,
    uint256 startTime,
    uint256 endTime
  );

  event BoughtNFT(
    address indexed nftAddress,
    uint256 indexed tokenId,
    uint256 price,
    address seller,
    address indexed buyer
  );
  event OfferedNFT(address indexed nftAddress, uint256 indexed tokenId, uint256 offerPrice, address indexed offerer);
  event CanceledOfferedNFT(
    address indexed nftAddress,
    uint256 indexed tokenId,
    uint256 offerPrice,
    address indexed offerer
  );
  event AcceptedNFT(
    address indexed nftAddress,
    uint256 indexed tokenId,
    uint256 offerPrice,
    address offerer,
    address indexed nftOwner
  );
  event CreatedAuction(
    address indexed nftAddress,
    uint256 indexed tokenId,
    uint256 price,
    uint256 minBidStep,
    uint256 startTime,
    uint256 endTime,
    address indexed creator
  );
  event PlacedBid(address indexed nftAddress, uint256 indexed tokenId, uint256 bidPrice, address indexed bidder);
  event CanceledAuction(address indexed nftAddress, uint256 indexed tokenId);

  event ResultedAuction(
    address indexed nftAddress,
    uint256 indexed tokenId,
    address creator,
    address indexed winner,
    uint256 price,
    address caller
  );

  modifier onlyListedNFT(NFT calldata nft) {
    ListNFT memory listedNFT = listNfts[abi.encode(nft)];
    require(
      listedNFT.seller != address(0) && listedNFT.price > 0 && block.timestamp <= listedNFT.endTime,
      'not listed'
    );
    _;
  }

  modifier onlyNotListed(NFT calldata nft) {
    ListNFT memory listedNFT = listNfts[abi.encode(nft)];
    require(listedNFT.seller == address(0) && listedNFT.price == 0, 'already listed');
    _;
  }

  modifier onAuction(NFT memory nft) {
    NFT memory auctionNft = auctionNfts[abi.encode(nft)].nft;
    require(auctionNft.addr == nft.addr && auctionNft.tokenId == nft.tokenId, 'auction is not created');
    _;
  }

  modifier notOnAuction(NFT calldata nft) {
    AuctionNFT memory auction = auctionNfts[abi.encode(nft)];
    require(auction.nft.addr == address(0) || auction.success, 'auction already created');
    _;
  }

  modifier onlyOfferedNFT(OfferNFTParams calldata params) {
    OfferNFT memory offer = offerNfts[abi.encode(params.nft)][params.offerer][params.price];
    require(offer.offerer == params.offerer && offer.offerPrice == params.price, 'not offered');
    require(!offer.accepted, 'already accepted');
    _;
  }

  /**
   * @notice List NFT on Marketplace
   * @param params The listing parameters (nft, tokenId, price, startTime, endTime)
   */
  function listNft(ListingParams calldata params) external returns (uint256) {
    require(block.timestamp <= params.startTime && params.endTime > params.startTime, 'invalid time range');
    require(params.price > MINIMUM_BUYING_FEE, 'less than minimum buying fee');

    IERC721 nftContract = IERC721(params.nft.addr);
    bytes memory encodedNft = abi.encode(params.nft);
    ListNFT memory listedNFT = listNfts[encodedNft];

    // If the NFT is already listed, the seller must be the same as the caller.
    if (listedNFT.seller != address(0)) {
      require(listedNFT.seller == msg.sender, 'not seller');
    } else {
      // Otherwise, the caller must be the owner of the NFT.
      require(nftContract.ownerOf(params.nft.tokenId) == msg.sender, 'not nft owner');
      // The caller must have enough tokens for the platform fee.
      require(loveToken.balanceOf(msg.sender) >= platformListingFee, 'no tokens for platform fee');
      // The caller must transfer the NFT to the marketplace contract.
      nftContract.transferFrom(msg.sender, address(this), params.nft.tokenId);
      // The caller must transfer the platform fee to the marketplace contract.
      loveToken.transferFrom(msg.sender, address(this), platformListingFee);
    }

    // Update the listing.
    listNfts[encodedNft] = ListNFT({
      nft: params.nft,
      price: params.price,
      seller: msg.sender,
      startTime: params.startTime,
      endTime: params.endTime
    });
    emit ListedNFT(params.nft.addr, params.nft.tokenId, params.price, msg.sender, params.startTime, params.endTime);
    return platformListingFee;
  }

  function getListedNFT(NFT calldata nft) external view returns (ListNFT memory) {
    return listNfts[abi.encode(nft)];
  }

  /**
   * @notice Cancel listed NFT
   * @param nft NFT address
   */
  function cancelListedNFT(NFT calldata nft) external onlyListedNFT(nft) {
    bytes memory encodedNft = abi.encode(nft);
    ListNFT memory listedNFT = listNfts[encodedNft];
    // Ensure the sender is the seller
    require(listedNFT.seller == msg.sender, 'not seller');

    delete listNfts[encodedNft];
    // Transfer the NFT back to the seller
    IERC721(nft.addr).safeTransferFrom(address(this), msg.sender, nft.tokenId);

    emit CanceledListedNFT(
      listedNFT.nft.addr,
      listedNFT.nft.tokenId,
      listedNFT.price,
      listedNFT.seller,
      listedNFT.startTime,
      listedNFT.endTime
    );
  }

  /**
   * @notice Buy NFT on Marketplace
   * @param nft NFT address
   * @param price listed price
   * @return priceWithRoyalty price with fees
   */
  function buyNFT(NFT calldata nft, uint256 price) external onlyListedNFT(nft) returns (uint256 priceWithRoyalty) {
    bytes memory encodedNft = abi.encode(nft);
    ListNFT memory listedNft = listNfts[encodedNft];
    require(price >= listedNft.price, 'less than listed price');

    delete listNfts[encodedNft];
    TokenRoyaltyInfo memory royaltyInfo = tryGetRoyaltyInfo(nft, price);
    transferRoyalty(royaltyInfo, msg.sender);
    // remove nft from listing
    (uint256 amount, uint256 buyingFee) = calculateFeeAndAmount(price);
    // transfer platform fee to marketplace contract
    loveToken.transferFrom(msg.sender, address(this), buyingFee);

    // Transfer payment to nft owner
    loveToken.transferFrom(msg.sender, listedNft.seller, amount);

    // Transfer NFT to buyer
    IERC721(nft.addr).safeTransferFrom(address(this), msg.sender, nft.tokenId);

    emit BoughtNFT(nft.addr, nft.tokenId, price, listedNft.seller, msg.sender);
    return price + royaltyInfo.royaltyAmount;
  }

  /**
   * @notice Offer NFT on Marketplace
   * @param params OfferNFTParams
   * @return offerPriceWithRoyalty offer price with royalty
   */
  function offerNFT(OfferNFTParams calldata params) external notOnAuction(params.nft) returns (uint256) {
    require(params.price > MINIMUM_BUYING_FEE, 'price less minimum commission');
    TokenRoyaltyInfo memory royaltyInfo = tryGetRoyaltyInfo(params.nft, params.price);
    uint256 offerPriceWithRoyalty = params.price + royaltyInfo.royaltyAmount;

    reservedBalance += offerPriceWithRoyalty;

    loveToken.transferFrom(msg.sender, address(this), offerPriceWithRoyalty);

    offerNfts[abi.encode(params.nft)][msg.sender][params.price] = OfferNFT({
      nft: params.nft,
      offerer: msg.sender,
      offerPrice: params.price,
      accepted: false,
      royaltyInfo: royaltyInfo
    });

    emit OfferedNFT(params.nft.addr, params.nft.tokenId, params.price, msg.sender);
    return offerPriceWithRoyalty;
  }

  /**
   * @notice Cancel offer
   * @param params The offer parameters (nft, tokenId, offerer, price)
   * @return offerPriceWithRoyalty offer price with royalty
   */
  function cancelOfferNFT(OfferNFTParams calldata params) external onlyOfferedNFT(params) returns (uint256) {
    require(params.offerer == msg.sender, 'not offerer');

    bytes memory encodedNft = abi.encode(params.nft);
    OfferNFT memory offer = offerNfts[encodedNft][params.offerer][params.price];
    delete offerNfts[encodedNft][params.offerer][params.price];

    uint256 offerPriceWithRoyalty = offer.offerPrice + offer.royaltyInfo.royaltyAmount;
    reservedBalance -= offerPriceWithRoyalty;

    loveToken.transfer(offer.offerer, offerPriceWithRoyalty);

    emit CanceledOfferedNFT(offer.nft.addr, offer.nft.tokenId, offer.offerPrice, params.offerer);
    return offerPriceWithRoyalty;
  }

  /**
   * @notice Accept offer
   * @param params The offer parameters (nft, tokenId, offerer, price)
   * @return amount amount transfer to seller
   */
  function acceptOfferNFT(
    OfferNFTParams calldata params
  ) external onlyOfferedNFT(params) nonReentrant returns (uint256) {
    bytes memory encodedNft = abi.encode(params.nft);
    OfferNFT storage offer = offerNfts[encodedNft][params.offerer][params.price];
    ListNFT memory list = listNfts[encodedNft];
    address from = address(this);
    // If the NFT is listed, the seller is the owner of the contract
    if (list.seller != address(0)) {
      require(msg.sender == list.seller, 'not listed owner');
      delete listNfts[encodedNft];
    } else {
      // If not, the seller is the owner of the NFT
      require(IERC721(params.nft.addr).ownerOf(params.nft.tokenId) == msg.sender, 'not nft owner');
      from = msg.sender;
    }

    TokenRoyaltyInfo memory royaltyInfo = offer.royaltyInfo;
    uint256 offerPriceWithRoyalty = params.price + royaltyInfo.royaltyAmount;

    // Release reserved balance
    reservedBalance -= offerPriceWithRoyalty;
    offer.accepted = true;

    transferRoyalty(royaltyInfo, address(this));

    // Calculate & Transfer platform fee
    (uint256 amount, ) = calculateFeeAndAmount(params.price);

    // Transfer LOVE to seller
    loveToken.transfer(msg.sender, amount);
    // Transfer NFT to offerer
    IERC721(params.nft.addr).safeTransferFrom(from, params.offerer, params.nft.tokenId);

    emit AcceptedNFT(params.nft.addr, params.nft.tokenId, params.price, params.offerer, msg.sender);
    return amount;
  }

  /**
   * @notice Create auction for NFT
   * @dev This function allows users to create an auction for an NFT
   * @param params The auction parameters (nft, tokenId, initialPrice, minBidStep, startTime, endTime)
   */
  function createAuction(AuctionParams calldata params) external notOnAuction(params.nft) {
    // Cast the nftAddress to the IERC721 interface
    IERC721 nft = IERC721(params.nft.addr);

    // Check if the caller is the owner of the NFT
    require(nft.ownerOf(params.nft.tokenId) == msg.sender, 'not nft owner');
    require(loveToken.balanceOf(msg.sender) >= platformListingFee, 'no tokens for platform fee');
    // The caller must transfer the platform fee to the marketplace contract.
    loveToken.transferFrom(msg.sender, address(this), platformListingFee);
    // Transfer the NFT from the caller to the contract
    nft.transferFrom(msg.sender, address(this), params.nft.tokenId);

    // Store the auction details in the auctionNfts mapping
    auctionNfts[abi.encode(params.nft)] = AuctionNFT({
      nft: params.nft,
      creator: msg.sender,
      initialPrice: params.initialPrice,
      minBidStep: params.minBidStep,
      startTime: params.startTime,
      endTime: params.endTime,
      lastBidder: address(0),
      highestBid: params.initialPrice,
      royaltyInfo: TokenRoyaltyInfo(address(0), 0),
      winner: address(0),
      success: false
    });

    emit CreatedAuction(
      params.nft.addr,
      params.nft.tokenId,
      params.initialPrice,
      params.minBidStep,
      params.startTime,
      params.endTime,
      msg.sender
    );
  }

  /**
   * @notice Cancel auction
   * @param nft NFT address
   */
  function cancelAuction(NFT calldata nft) external onAuction(nft) {
    bytes memory encodedNft = abi.encode(nft);
    AuctionNFT memory auction = auctionNfts[encodedNft];
    require(auction.creator == msg.sender, 'not auction creator');
    require(!auction.success, 'auction already success');
    require(auction.lastBidder == address(0), 'already have bidder');

    delete auctionNfts[encodedNft];
    IERC721(nft.addr).safeTransferFrom(address(this), msg.sender, nft.tokenId);

    emit CanceledAuction(nft.addr, nft.tokenId);
  }

  /**
   * @notice Place bid on auction
   * @param nft NFT address
   * @param bidPrice bid price (must be greater than highest bid + min bid step)
   * @return bidPriceWithRoyalty bid price with royalty
   */
  function bidPlace(NFT calldata nft, uint256 bidPrice) external onAuction(nft) nonReentrant returns (uint256) {
    AuctionNFT storage auction = auctionNfts[abi.encode(nft)];
    require(block.timestamp >= auction.startTime, 'auction not started');
    require(block.timestamp <= auction.endTime, 'auction ended');
    require(bidPrice >= auction.highestBid + auction.minBidStep, 'less than min bid price');

    TokenRoyaltyInfo memory royaltyInfo = tryGetRoyaltyInfo(nft, bidPrice);
    uint256 lastBidPriceWithRoyalty = 0;
    uint256 bidPriceWithRoyalty = bidPrice + royaltyInfo.royaltyAmount;

    if (auction.lastBidder != address(0)) {
      address lastBidder = auction.lastBidder;
      uint256 lastBidPrice = auction.highestBid;
      // Transfer back to last bidder
      lastBidPriceWithRoyalty = lastBidPrice + auction.royaltyInfo.royaltyAmount;
      loveToken.transfer(lastBidder, lastBidPriceWithRoyalty);
    }

    reservedBalance += bidPriceWithRoyalty - lastBidPriceWithRoyalty;
    // Set new highest bid price & bidder
    auction.lastBidder = msg.sender;
    auction.highestBid = bidPrice;
    auction.royaltyInfo = royaltyInfo;

    loveToken.transferFrom(msg.sender, address(this), bidPriceWithRoyalty);

    emit PlacedBid(nft.addr, nft.tokenId, bidPrice, msg.sender);
    return bidPriceWithRoyalty;
  }

  /**
   * @notice Result auctions
   * @param nft NFT
   */
  function resultAuction(NFT calldata nft) external returns (uint256) {
    uint amount = _resultAuction(nft);
    reservedBalance -= amount;
    return amount;
  }

  /**
   * @notice Result multiple auctions
   * @param nfts NFT (nftAddres, tokenId)
   */
  function resultAuctions(NFT[] calldata nfts) external returns (uint256) {
    uint256 totalAmount = 0;

    for (uint256 i = 0; i < nfts.length; i++) {
      // Result each auction and accumulate the amount transferred to the auction creator
      uint256 amount = _resultAuction(nfts[i]);
      totalAmount += amount;
    }
    reservedBalance -= totalAmount;
    return totalAmount;
  }

  /**
   * @notice Get auction info by NFT address and token id
   * @param nft NFT address
   * @return AuctionNFT struct
   */
  function getAuction(NFT calldata nft) external view returns (AuctionNFT memory) {
    return auctionNfts[abi.encode(nft)];
  }

  /**
   * @notice Transfer fee to fee receiver contract
   * @dev should set feeReceiver (updateFeeReceiver()) address before call this function
   * @param amount Fee amount
   */
  function transferFee(uint256 amount) external hasRole('admin') {
    require(feeReceiver != address(0), 'invalid feeReceiver address');
    require(getAvailableBalance() >= amount, 'insufficient balance (reserved)');
    require(loveToken.transfer(feeReceiver, amount), 'unable to transfer token');
  }

  /**
   * @notice Set platform fee
   * @param newPlatformFee new platform fee
   */
  function setPlatformFee(uint256 newPlatformFee) external onlyOwner {
    platformFee = newPlatformFee;
    emit ChangedPlatformFee(newPlatformFee);
  }

  /**
   * @notice Set platform fee contract (LoveDrop)
   * @param newFeeReceiver new fee receiver address
   */
  function updateFeeReceiver(address newFeeReceiver) external onlyOwner {
    require(newFeeReceiver != address(0), 'invalid address');
    feeReceiver = newFeeReceiver;

    emit ChangedFeeReceiver(newFeeReceiver);
  }

  /**
   * @notice Calculate fee and amount
   * @param price price
   * @return amount amount transfer to seller
   * @return fee fee transfer to marketplace contract
   */
  function calculateFeeAndAmount(uint256 price) public view returns (uint256 amount, uint256 fee) {
    uint256 fee1e27 = (price * platformFee * 1e27) / 100;
    uint256 fee = fee1e27 / 1e27;
    if (fee < MINIMUM_BUYING_FEE) {
      fee = MINIMUM_BUYING_FEE;
    }
    return (price - fee, fee);
  }

  /**
   * @notice Get available balance
   * @return availableBalance available balance (not reserved)
   */
  function getAvailableBalance() public view returns (uint256 availableBalance) {
    return loveToken.balanceOf(address(this)) - reservedBalance;
  }

  function _resultAuction(NFT calldata nft) internal onAuction(nft) returns (uint256) {
    AuctionNFT storage auction = auctionNfts[abi.encode(nft)];
    require(!auction.success, 'already resulted');
    require(block.timestamp > auction.endTime, 'auction not ended');
    address creator = auction.creator;
    address winner = auction.lastBidder;
    uint256 highestBid = auction.highestBid;
    if (winner == address(0)) {
      // If no one bid, transfer NFT back to creator
      delete auctionNfts[abi.encode(nft)];
      IERC721(nft.addr).safeTransferFrom(address(this), creator, nft.tokenId);
      emit CanceledAuction(nft.addr, nft.tokenId);
      return 0;
    }
    auction.success = true;
    auction.winner = winner;
    TokenRoyaltyInfo memory royaltyInfo = auction.royaltyInfo;
    // Calculate royalty fee and transfer to recipient
    transferRoyalty(royaltyInfo, address(this));

    // Calculate platform fee
    (uint256 amount, ) = calculateFeeAndAmount(highestBid);

    // Transfer to auction creator
    require(loveToken.transfer(creator, amount), 'transfer to creator failed');
    // Transfer NFT to the winner
    IERC721(nft.addr).safeTransferFrom(address(this), winner, nft.tokenId);

    emit ResultedAuction(nft.addr, nft.tokenId, creator, winner, highestBid, msg.sender);
    return highestBid + royaltyInfo.royaltyAmount;
  }

  function tryGetRoyaltyInfo(NFT calldata nft, uint256 price) internal view returns (TokenRoyaltyInfo memory) {
    TokenRoyaltyInfo memory royaltyInfo;
    if (ERC2981(nft.addr).supportsInterface(type(IERC2981).interfaceId)) {
      (address royaltyRecipient, uint256 amount) = IERC2981(nft.addr).royaltyInfo(nft.tokenId, price);
      if (amount > price / 5) amount = price / 5;
      royaltyInfo = TokenRoyaltyInfo(royaltyRecipient, amount);
    }
    return royaltyInfo;
  }

  function transferRoyalty(TokenRoyaltyInfo memory royaltyInfo, address from) internal {
    bool result;
    if (royaltyInfo.royaltyReceiver != address(0) && royaltyInfo.royaltyAmount > 0) {
      if (from == address(this)) {
        result = loveToken.transfer(royaltyInfo.royaltyReceiver, royaltyInfo.royaltyAmount);
      } else {
        result = loveToken.transferFrom(from, royaltyInfo.royaltyReceiver, royaltyInfo.royaltyAmount);
      }
      require(result, 'royalty transfer failed');
    }
  }
}