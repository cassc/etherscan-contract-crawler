// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**
 * @title Model data related with Auction
 */
library AuctionDomain {
  // Platform KIND
  bytes4 public constant SBINFT_PF_KIND = bytes4(keccak256("SBINFT"));
  bytes4 public constant EXTERNAL_PF_KIND = bytes4(keccak256("EXTERNAL"));

  // ORIGIN_KIND
  bytes4 public constant NANAKUSA_ORIGIN_KIND = bytes4(keccak256("NANAKUSA"));
  bytes4 public constant PARTNER_ORIGIN_KIND = bytes4(keccak256("PARTNER"));

  bytes4 public constant NON_EXPANDABLE_AUCTION_KIND =
    bytes4(keccak256("NON_EXPANDABLE")); // Non Expand
  bytes4 public constant EXPANDABLE_AUCTION_KIND =
    bytes4(keccak256("EXPANDABLE")); // 5 minute Expand Auction

  bytes4 public constant NATIVE_BID_MODE = bytes4(keccak256("NATIVE"));
  bytes4 public constant ERC20_BID_MODE = bytes4(keccak256("ERC20"));
  bytes4 public constant CREDIT_CARD_BID_MODE =
    bytes4(keccak256("CREDIT_CARD"));
  bytes4 public constant OTHER_BLOCKCHAIN_BID_MODE =
    bytes4(keccak256("OTHER_BLOCKCHAIN"));

  struct Asset {
    bytes4 originKind;
    address asset;
    uint256 assetId;
    uint16 partnerFeeRate; // only set when originKind = PARTNER_ORIGIN_KIND
    uint8 isSecondarySale;
  }

  struct AuctionType {
    bytes4 auctionKind; // NON_EXPANDABLE | EXPANDABLE
    bytes4 bidMode; // Bid currency kind (Native,ERC20,Fiat)
    address paymentToken; // Native & Fiat is zeroAddress and for ERC20 is ContractAddress
  }

  struct BidStatus {
    address currentTopBidder;
    address payable refundTo; // If zero address means FeeRciever is the  currentTopBidder
    uint256 currentPrice;
    address[] bidderList;
    uint256[] bidPriceHistory;
  }

  struct Auction {
    uint256 auctionId; //auction Id
    bytes4 pfKind;
    address payable creatorAddress;
    Asset asset;
    AuctionType auctionType;
    uint256 startPrice;
    uint256 startTime;
    uint256 endTime;
    uint16 pfFeeRate;
    uint16 externalPfFeeRate; //if zero means Auction Platform is SBINFTMarket
    address platformSigner;
  }

  struct Bid {
    uint256 auctionId; //auction Id
    address bidder; //For NFT recieve address
    address payable refundTo; // Return destination of funds
    uint256 nonce; //bid log array length bidders hystory
    uint256 price; //Nativeand Credit bid Auction is 0
  }

  struct AuctionResult {
    uint256 auctionId; //auction Id
    address asset;
    uint256 assetId;
    address winner; // Successful bidder
    uint256 finalPrice;
  }

  /**
   * @dev Checks if it's a valid platform kind
   *
   * @param _platformKind bytes4
   */
  function _isValidPlatformKind(
    bytes4 _platformKind
  ) internal pure returns (bool) {
    return (_platformKind == SBINFT_PF_KIND ||
      _platformKind == EXTERNAL_PF_KIND);
  }

  /**
   * @dev Checks if it's a valid origin kind
   *
   * @param _originKind bytes4
   */
  function _isValidOriginKind(bytes4 _originKind) internal pure returns (bool) {
    return (_originKind == NANAKUSA_ORIGIN_KIND ||
      _originKind == PARTNER_ORIGIN_KIND);
  }

  /**
   * @dev Checks if it's a valid auction kind
   *
   * @param _auctionKind bytes4
   */
  function _isValidAuctionKind(
    bytes4 _auctionKind
  ) internal pure returns (bool) {
    return (_auctionKind == NON_EXPANDABLE_AUCTION_KIND ||
      _auctionKind == EXPANDABLE_AUCTION_KIND);
  }

  /**
   * @dev Checks if it's a valid bid mode
   *
   * @param _bidMode bytes4
   */
  function _isValidBidMode(bytes4 _bidMode) internal pure returns (bool) {
    return (_bidMode == NATIVE_BID_MODE ||
      _bidMode == ERC20_BID_MODE ||
      _bidMode == CREDIT_CARD_BID_MODE ||
      _bidMode == OTHER_BLOCKCHAIN_BID_MODE);
  }

  /**
   * @dev Checks if payment mode is onchain
   *
   * @param _bidMode bytes4
   */
  function _isOnchainBidMode(bytes4 _bidMode) internal pure returns (bool) {
    return (_bidMode == NATIVE_BID_MODE || _bidMode == ERC20_BID_MODE);
  }

  /**
   * @dev Checks if origin kind is partner
   *
   * @param _originKind bytes4
   */
  function _isPartnerOrigin(bytes4 _originKind) internal pure returns (bool) {
    return (_originKind == PARTNER_ORIGIN_KIND);
  }

  /**
   * @dev Checks if origin kind is partner
   *
   * @param _pfKind bytes4
   */
  function _isExternalPFOrigin(bytes4 _pfKind) internal pure returns (bool) {
    return (_pfKind == EXTERNAL_PF_KIND);
  }

  /**
   * @dev Checks if it's a Secondary Sale
   *
   * @param _secondarySale uint8
   */
  function _isSecondarySale(uint8 _secondarySale) internal pure returns (bool) {
    return (_secondarySale == 1);
  }

  // ---- EIP712 関連 ----
  bytes32 constant ASSET_TYPEHASH =
    keccak256(
      "Asset(bytes4 originKind,address asset,uint256 assetId,uint16 partnerFeeRate,uint8 isSecondarySale)"
    );

  bytes32 constant AUCTION_TYPE_TYPEHASH =
    keccak256(
      "AuctionType(bytes4 auctionKind,bytes4 bidMode,address paymentToken)"
    );

  bytes32 constant AUCTION_TYPEHASH =
    keccak256(
      "Auction(uint256 auctionId,bytes4 pfKind,address creatorAddress,Asset asset,AuctionType auctionType,uint256 startPrice,uint256 startTime,uint256 endTime,uint16 pfFeeRate,uint16 externalPfFeeRate,address platformSigner)Asset(bytes4 originKind,address asset,uint256 assetId,uint16 partnerFeeRate,uint8 isSecondarySale)AuctionType(bytes4 auctionKind,bytes4 bidMode,address paymentToken)"
    );

  bytes32 constant BID_TYPEHASH =
    keccak256(
      "Bid(uint256 auctionId,address bidder,address refundTo,uint256 nonce,uint256 price)"
    );

  bytes32 constant AUCTION_RESULT_TYPEHASH =
    keccak256(
      "AuctionResult(uint256 auctionId,address asset,uint256 assetId,address winner,uint256 finalPrice)"
    );

  /**
   * @dev Create hash message of asset
   *
   * @param _asset Asset calldata
   */
  function _hashAsset(Asset calldata _asset) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encode(
          ASSET_TYPEHASH,
          _asset.originKind,
          _asset.asset,
          _asset.assetId,
          _asset.partnerFeeRate,
          _asset.isSecondarySale
        )
      );
  }

  /**
   * @dev Create hash message of auctionType
   *
   * @param _bidtype AuctionType calldata
   */
  function _hashAuctionType(
    AuctionType calldata _bidtype
  ) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encode(
          AUCTION_TYPE_TYPEHASH,
          _bidtype.auctionKind,
          _bidtype.bidMode,
          _bidtype.paymentToken
        )
      );
  }

  /**
   * @dev Create hash message of auction
   *
   * @param _auction Auction calldata
   */
  function _hashAuction(
    Auction calldata _auction
  ) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encode(
          AUCTION_TYPEHASH,
          _auction.auctionId,
          _auction.pfKind,
          _auction.creatorAddress,
          _hashAsset(_auction.asset),
          _hashAuctionType(_auction.auctionType),
          _auction.startPrice,
          _auction.startTime,
          _auction.endTime,
          _auction.pfFeeRate,
          _auction.externalPfFeeRate,
          _auction.platformSigner
        )
      );
  }

  /**
   * @dev Create hash message of bid
   *
   * @param _bid Bid calldata
   */
  function _hashBid(Bid calldata _bid) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encode(
          BID_TYPEHASH,
          _bid.auctionId,
          _bid.bidder,
          _bid.refundTo,
          _bid.nonce,
          _bid.price
        )
      );
  }

  /**
   * @dev Create hash message of auction result
   *
   * @param _result AuctionResult calldata
   */
  function _hashAuctionResult(
    AuctionResult calldata _result
  ) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encode(
          AUCTION_RESULT_TYPEHASH,
          _result.auctionId,
          _result.asset,
          _result.assetId,
          _result.winner,
          _result.finalPrice
        )
      );
  }
}