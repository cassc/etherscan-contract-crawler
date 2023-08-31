// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @notice The auction configuration for a specific NFT.
struct AuctionBasicState {
  /// @notice The address of the NFT contract.
  address nftContract;
  /// @notice The id of the NFT.
  uint256 tokenId;
  /// @notice The owner of the NFT which listed it in auction.
  address payable seller;
  /// @notice The current highest bidder in this auction.
  /// @dev This is `address(0)` until the first bid is placed.
  address payable highestBidder;
  /// @notice The difference between two subsequent bids, if no ending phase mechanics are applied.
  uint256 minimumIncrement;
  /// @notice The time at which this auction will not accept any new bids.
  /// @dev This is `0` until the first bid is placed in case of a reserve price triggered auction.
  uint256 end;
  /// @notice The latest price of the NFT in this auction.
  /// @dev This is set to the reserve price, and then to the highest bid once the auction has started.
  uint256 reservePriceOrHighestBid;
  bool isStandardAuction;
  bool isPrimarySale;
}

/// @notice The auction configuration for a specific NFT.
struct AuctionAdditionalConfiguration {
  /// @notice During the ending phase, the minimum increment becomes a percentage of the highest bid.
  uint256 endingPhase;
  /// @notice The price at which anyoane can aquire this NFT while the auction is ongoing.
  /// @dev This works only if the value is grater than the highest bid.
  uint256 buyOutPrice;
  /// @notice During the ending phase, add a minimum percentage increase each bid must meet.
  uint256 endingPhasePercentageFlip;
  /// @notice How long to extend the auction with (in seconds) from the last bid.
  uint256 extensionWindow;
  /// @notice The time at which this auction has kicked off
  /// @dev IMPORTANT - In order to save gas and not define another variable, when the auction is reserved price triggered
  /// we pass here the duration
  uint256 start;
  /// @notice Specifies if this is reserve price triggered auction.
  bool isReservePriceTriggered;
}

/// @notice All details related to an auction
struct AuctionState {
  /// @notice The address of the NFT contract.
  address nftContract;
  /// @notice The id of the NFT.
  uint256 tokenId;
  /// @notice The owner of the NFT which listed it in auction.
  address payable seller;
  /// @notice The difference between two subsequent bids, if no ending phase mechanics are applied.
  uint256 minimumIncrement;
  /// @notice During the ending phase, the minimum increment becomes a percentage of the highest bid.
  uint256 endingPhase;
  /// @notice During the ending phase, add a minimum percentage increase each bid must meet.
  uint256 endingPhasePercentageFlip;
  /// @notice How long to extend the auction with (in seconds) from the last bid.
  uint256 extensionWindow;
  /// @notice The time at which this auction has kicked off
  /// @dev IMPORTANT - In order to save gas and not define another variable, when the auction is reserved price triggered
  /// we pass here the duration
  uint256 start;
  /// @notice The time at which this auction will not accept any new bids.
  /// @dev This is `0` until the first bid is placed in case of a reserve price triggered auction.
  uint256 end;
  /// @notice The current highest bidder in this auction.
  /// @dev This is `address(0)` until the first bid is placed.
  address payable highestBidder;
  /// @notice The latest price of the NFT in this auction.
  /// @dev This is set to the reserve price, and then to the highest bid once the auction has started.
  uint256 reservePriceOrHighestBid;
  /// @notice The price at which anyoane can aquire this NFT while the auction is ongoing.
  /// @dev This works only if the value is grater than the highest bid.
  uint256 buyOutPrice;
  /// @notice Specifies if this is a primary sale or a secondary one.
  bool isPrimarySale;
  /// @notice Specifies if this is reserve price triggered auction.
  bool isReservePriceTriggered;
  bool isStandardAuction;
}
/// @notice The arguments  that need to be provided on an auction initialization.
struct InitAuctionArguments {
  address nftContract;
  uint256 tokenId;
  uint256 minimumIncrement;
  uint256 endingPhase;
  uint256 endingPhasePercentageFlip;
  uint256 extensionWindow;
  uint256 start;
  uint256 end;
  uint256 reservePrice;
  uint256 buyOutPrice;
  bool isReservePriceTriggered;
  bool isPrimarySale;
  bool isStandardAuction;
}

interface IAuctionSellingAgreementProvider {
  error NFTMarketAuction__EndingPhaseProvidedWithNopercentageFlip();
  error NFTMarketAuction__PercentageFlipGreaterThan100(uint256 percentageFlip);
  error NFTMarketAuction__StartGreaterThanEnd();
  error NFTMarketAuction__EndingPhaseGraterThanDuration(uint256 endingPhase);
  error NFTMarketAuction__ExrtensionWindowGraterThanEndingPhase(
    uint256 extensionWindow
  );

  /**
   * @notice Emitted when a bid is placed.
   * @param auctionId : The id of the auction this bid was for.
   * @param bidder    : The address of the bidder.
   * @param amount    : The amount of the bid.
   * @param endTime   : The new end time of the auction (which may have been extended by this bid).
   */
  event AuctionSellingAgreementBidPlaced(
    uint256 indexed auctionId,
    address indexed bidder,
    uint256 amount,
    uint256 endTime
  );

  /**
   * @notice Emitted when the buy out is triggered on an auction.
   * @param auctionId       : The id of the auction this bid was for.
   * @param buyer           : The buyer who triggered the buyOut.
   * @param buyOutAmount    : The amount of the bid.
   */
  event AuctionSellingAgreementBuyOutTriggered(
    uint256 indexed auctionId,
    address indexed buyer,
    uint256 buyOutAmount
  );

  /**
   * @notice Emitted when an auction is canceled.
   * @dev This is only possible if the auction has not received any bids.
   * @param auctionId : The id of the auction that was canceled.
   */
  event AuctionSellingAgreementCancelled(uint256 indexed auctionId);

  /**
   * @notice Emitted when an NFT is listed for auction.
   * @param auctionConfig The address of the seller.
   * @param auctionId The id of the auction that was created.
   *
   */
  event AuctionSellingAgreementCreated(
    InitAuctionArguments indexed auctionConfig,
    uint256 auctionId
  );

  /**
   * @notice Emitted when an auction that has already ended is settled,
   * indicating that the NFT has been transferred and revenue from the sale distributed.
   * @param auctionId The id of the auction that was finalized.
   * @param seller The address of the seller.
   * @param bidder The address of the highest bidder that won the NFT.
   * @param price The value of the highest bid
   */
  event AuctionSellingAgreementSettled(
    uint256 indexed auctionId,
    address indexed seller,
    address indexed bidder,
    uint256 price
  );

  /**
   * @notice If an auction has been created but has not yet received bids, it may be canceled by the seller.
   * @dev The NFT is transferred back to the owner.
   * @param auctionId The id of the auction to cancel.
   */
  function cancelAuctionSellingAgreement(uint256 auctionId) external;

  /**
   * @notice Creates an auction for the given NFT.
   * The NFT is held in escrow until the auction is finalized or canceled.
   * @param auctionConfig The auction configuration
   */
  function createAuctionSellingAgreement(
    InitAuctionArguments calldata auctionConfig
  ) external;

  /**
   * @notice If an auction has been created but has not yet received bids, it may be canceled by the seller.
   * @dev The NFT is transferred back to the owner.
   */
  function buyOutAuctionSellingAgreement(uint256 auctionId) external payable;

  /**
   * @notice Place a bid in an auction.
   * A bidder may place a bid which is at least the amount defined by `getMinBidAmount`.
   * If this is the first bid on a reserve priced triggered auction, the countdown will begin.
   * If there is already an outstanding bid, the previous bider will be refunded at this time
   * and if the bid is placed in the final moments of the auction, the countdown may be extended.
   * @param auctionId The id of the auction to bid on.
   */
  /* solhint-disable-next-line code-complexity */
  function placeBidOnAuctionSellingAgreement(
    uint256 auctionId
  ) external payable;

  /**
   * @notice Settle an auction that has already ended.
   * This will send the NFT to the highest bidder and distribute revenue for this sale.
   */
  function settleAuctionSellingAgreement(uint256 auctionId) external payable;
}