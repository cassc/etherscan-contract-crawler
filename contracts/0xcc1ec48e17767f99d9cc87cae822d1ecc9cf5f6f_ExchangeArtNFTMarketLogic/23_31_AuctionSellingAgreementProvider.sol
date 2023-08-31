// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../libraries/ERC721Checks.sol";
import "../libraries/NumericChecks.sol";
import "../libraries/AuctionSellingAgreementChecks.sol";

import "./shared/PaymentsAware.sol";

import "./IdGenerator.sol";
import "../interfaces/IAuctionSellingAgreementProvider.sol";

/**
 * @title Allows the owner of an NFT to list it in auction.
 * @notice NFTs in auction are escrowed in the market contract.
 */
abstract contract AuctionSellingAgreementProvider is
  Initializable,
  IdGenerator,
  IAuctionSellingAgreementProvider,
  PaymentsAware,
  ReentrancyGuardUpgradeable
{
  using AddressUpgradeable for address payable;
  using ERC721Checks for IERC721;
  using NumericChecks for uint256;
  using AuctionSellingAgreementChecks for AuctionBasicState;
  using AuctionSellingAgreementChecks for uint256;

  //todo change these
  uint256 private constant STANDARD_EXTENSION_WINDOW = 5 minutes;
  uint256 private constant STANDARD_DURATION = 24 hours;
  uint256 private constant STANDARD_ENDING_PHASE = 15 minutes;
  uint256 private constant STANDARD_ENDING_PHASE_PERCENTAGE_FLIP = 10; // percentage;

  /// @notice The basic auction configuration
  mapping(address => mapping(uint256 => uint256))
    private nftContractToTokenIdToAuctionId;
  /// @notice The auction id for a specific NFT.
  mapping(uint256 => AuctionBasicState) private auctionIdToAuctionBasicState;
  /// @notice Extra configurations if the sellers opts in for this feature
  mapping(uint256 => AuctionAdditionalConfiguration)
    private auctionIdToAuctioAdditionalConfigurations;

  /// @notice Confirms that the configs provided are correct
  modifier onlyValidAuctionConfig(InitAuctionArguments memory configs) {
    configs.reservePrice.mustBeValidAmount();
    configs.minimumIncrement.mustBeValidAmount();
    // add buyOutPrice check;
    if (!configs.isStandardAuction) {
      if (configs.endingPhasePercentageFlip == 0 && configs.endingPhase != 0) {
        revert NFTMarketAuction__EndingPhaseProvidedWithNopercentageFlip();
      }
      if (configs.endingPhasePercentageFlip >= 100) {
        revert NFTMarketAuction__PercentageFlipGreaterThan100(
          configs.endingPhasePercentageFlip
        );
      }
      if (!configs.isReservePriceTriggered && configs.start > configs.end) {
        revert NFTMarketAuction__StartGreaterThanEnd();
      }
      if (
        (!configs.isReservePriceTriggered &&
          configs.endingPhase > configs.end - configs.start) ||
        (configs.isReservePriceTriggered && configs.endingPhase > configs.start)
      ) {
        revert NFTMarketAuction__EndingPhaseGraterThanDuration(
          configs.endingPhase
        );
      }
      if (configs.extensionWindow > configs.endingPhase) {
        revert NFTMarketAuction__ExrtensionWindowGraterThanEndingPhase(
          configs.extensionWindow
        );
      }
    }

    _;
  }

  /**
   * @dev see {IExchangeArtNFTMarketAuction - createAuctionSellingAgreement}
   */
  function createAuctionSellingAgreement(
    InitAuctionArguments memory auctionConfig
  )
    external
    nonReentrant
    // todo remove onlyvalidfunction and add a check to be called only for configurable functions
    onlyValidAuctionConfig(auctionConfig)
  {
    IERC721 nftContract = IERC721(auctionConfig.nftContract);
    uint256 auctionId = nftContractToTokenIdToAuctionId[
      auctionConfig.nftContract
    ][auctionConfig.tokenId];

    nftContract.sellerMustBeOwner(auctionConfig.tokenId, msg.sender);
    nftContract.marketplaceMustBeApproved(msg.sender);
    auctionId.mustNotExist();

    nftContract.transferFrom(msg.sender, address(this), auctionConfig.tokenId);
    uint256 newAuctionId = getSellingAgreementId();
    incrementSellingAgreementId();

    // Store the auction details
    nftContractToTokenIdToAuctionId[auctionConfig.nftContract][
      auctionConfig.tokenId
    ] = newAuctionId;
    AuctionBasicState storage basicAuctionConfig = auctionIdToAuctionBasicState[
      newAuctionId
    ];

    basicAuctionConfig.nftContract = auctionConfig.nftContract;
    basicAuctionConfig.tokenId = auctionConfig.tokenId;
    basicAuctionConfig.seller = payable(msg.sender);
    basicAuctionConfig.reservePriceOrHighestBid = auctionConfig.reservePrice;
    basicAuctionConfig.isPrimarySale = auctionConfig.isPrimarySale;
    basicAuctionConfig.isStandardAuction = auctionConfig.isStandardAuction;
    basicAuctionConfig.minimumIncrement = auctionConfig.minimumIncrement;

    // If is not a reserve price triggered auction start immediately
    if (!auctionConfig.isReservePriceTriggered) {
      basicAuctionConfig.end = auctionConfig.end;
    }
    if (!auctionConfig.isStandardAuction) {
      AuctionAdditionalConfiguration
        storage additionalConfigurations = auctionIdToAuctioAdditionalConfigurations[
          newAuctionId
        ];
      additionalConfigurations.endingPhase = auctionConfig.endingPhase;
      additionalConfigurations.buyOutPrice = auctionConfig.buyOutPrice;

      additionalConfigurations.endingPhasePercentageFlip = auctionConfig
        .endingPhasePercentageFlip;
      additionalConfigurations.extensionWindow = auctionConfig.extensionWindow;
      additionalConfigurations.start = auctionConfig.start;
      additionalConfigurations.isReservePriceTriggered = auctionConfig
        .isReservePriceTriggered;
      //auction.end = 0;
    }

    emit AuctionSellingAgreementCreated(auctionConfig, auctionId);
  }

  /**
   * @dev see {IExchangeArtNFTMarketAuction - cancelAuctionSellingAgreement}
   */
  function cancelAuctionSellingAgreement(
    uint256 auctionId
  ) external nonReentrant {
    AuctionBasicState memory auction = auctionIdToAuctionBasicState[auctionId];
    IERC721 nftContract = IERC721(auction.nftContract);

    auction.callerMustBeSeller(msg.sender);
    auction.mustExist();
    auction.mustNotHaveBids();

    // Remove the auction.
    delete nftContractToTokenIdToAuctionId[auction.nftContract][
      auction.tokenId
    ];
    delete auctionIdToAuctionBasicState[auctionId];
    if (!auction.isStandardAuction) {
      delete auctionIdToAuctioAdditionalConfigurations[auctionId];
    }

    nftContract.transferFrom(address(this), msg.sender, auction.tokenId);

    emit AuctionSellingAgreementCancelled(auctionId);
  }

  /**
   * @dev see {IExchangeArtNFTMarketAuction - buyOutAuctionSellingAgreement}
   */
  function buyOutAuctionSellingAgreement(
    uint256 auctionId
  ) external payable nonReentrant {
    AuctionBasicState memory auctionBasicState = auctionIdToAuctionBasicState[
      auctionId
    ];

    IERC721 nftContract = IERC721(auctionBasicState.nftContract);
    auctionBasicState.mustExist();
    auctionBasicState.mustBeConfigurable();

    AuctionAdditionalConfiguration
      memory auctionAdditionalConfigurations = auctionIdToAuctioAdditionalConfigurations[
        auctionId
      ];

    uint256 totalAmountFeesIncluded = auctionBasicState.isPrimarySale
      ? auctionAdditionalConfigurations.buyOutPrice +
        (auctionAdditionalConfigurations.buyOutPrice *
          EXCHANGE_ART_PRIMARY_FEE) /
        10_000
      : auctionAdditionalConfigurations.buyOutPrice +
        (auctionAdditionalConfigurations.buyOutPrice *
          EXCHANGE_ART_SECONDARY_FEE) /
        10_000;

    auctionBasicState.mustBeOngoing(
      block.timestamp,
      auctionAdditionalConfigurations.isReservePriceTriggered
    );

    auctionAdditionalConfigurations.buyOutPrice.mustBeGreaterThan(
      auctionBasicState.reservePriceOrHighestBid
    );
    msg.value.mustBeEqualTo(totalAmountFeesIncluded);

    // Remove the auction.
    delete nftContractToTokenIdToAuctionId[auctionBasicState.nftContract][
      auctionBasicState.tokenId
    ];
    delete auctionIdToAuctionBasicState[auctionId];
    delete auctionIdToAuctioAdditionalConfigurations[auctionId];

    nftContract.transferFrom(
      address(this),
      msg.sender,
      auctionBasicState.tokenId
    );

    //Distribute revenue for this sale.
    _handlePayments(
      auctionBasicState.nftContract,
      auctionBasicState.tokenId,
      auctionAdditionalConfigurations.buyOutPrice,
      auctionBasicState.seller,
      auctionBasicState.isPrimarySale
    );

    emit AuctionSellingAgreementBuyOutTriggered(
      auctionId,
      msg.sender,
      auctionAdditionalConfigurations.buyOutPrice
    );
  }

  /**
   * @dev see {IExchangeArtNFTMarketAuction - placeBidOnAuctionSellingAgreement}
   */
  function placeBidOnAuctionSellingAgreement(
    uint256 auctionId
  ) public payable nonReentrant {
    AuctionBasicState storage auctionDetails = auctionIdToAuctionBasicState[
      auctionId
    ];
    AuctionAdditionalConfiguration
      memory auctionAdditionalConfigurations = auctionIdToAuctioAdditionalConfigurations[
        auctionId
      ];

    // todo - more elegant way to rapresent this
    uint256 primaryFeePercentage = (msg.value / 105) * 5;
    uint256 bid = auctionDetails.isPrimarySale
      ? msg.value - primaryFeePercentage
      : msg.value / (1 + 25e16); // 25e16 is 0.025 in fixed-point representation (2.5% in 1/10000)
    auctionDetails.mustExist();
    // Sellers cannot bid on their auctions
    auctionDetails.callerMustNotBeSeller(msg.sender);
    auctionDetails.callerCannotBeHighestBidder(msg.sender);
    bid.mustBeValidAmount();

    uint256 currentTime = block.timestamp;
    bool isFirstBid = auctionDetails.highestBidder == address(0);
    bool isStandardAuction = auctionDetails.isStandardAuction;

    if (
      isStandardAuction ||
      (!isStandardAuction &&
        auctionAdditionalConfigurations.isReservePriceTriggered)
    ) {
      // wen need to start the auction if this is the first bid
      if (isFirstBid) {
        if (isStandardAuction) {
          auctionDetails.end = currentTime + STANDARD_DURATION;
        } else {
          AuctionAdditionalConfiguration
            storage s_auctionAdditionalConfigurations = auctionIdToAuctioAdditionalConfigurations[
              auctionId
            ];
          auctionDetails.end =
            currentTime +
            auctionAdditionalConfigurations.start;
          s_auctionAdditionalConfigurations.start = currentTime;
        }
      } else {
        // Auction is ongoing, check to see if it's still active
        auctionDetails.end.mustBeGreaterThanOrEqual(currentTime);
      }
    } else {
      currentTime.mustBeGreaterThanOrEqual(
        auctionAdditionalConfigurations.start
      );
    }
    uint256 minBidAmount = isFirstBid
      ? auctionDetails.reservePriceOrHighestBid
      : getMinBidAmount(auctionId);

    uint256 minBidAmountFeesIncluded = auctionDetails.isPrimarySale
      ? minBidAmount + (minBidAmount * EXCHANGE_ART_PRIMARY_FEE) / 10_000
      : minBidAmount + (minBidAmount * EXCHANGE_ART_SECONDARY_FEE) / 10_000;

    msg.value.mustBeGreaterThanOrEqual(minBidAmountFeesIncluded);
    bid.mustBeGreaterThanOrEqual(minBidAmount);

    if (isFirstBid) {
      // Store the bid details.
      auctionDetails.reservePriceOrHighestBid = bid;
      auctionDetails.highestBidder = payable(msg.sender);
    } else {
      // Update bidder state
      uint256 previousBid = auctionDetails.reservePriceOrHighestBid;
      address payable previousBidder = auctionDetails.highestBidder;
      auctionDetails.reservePriceOrHighestBid = bid;
      auctionDetails.highestBidder = payable(msg.sender);

      // Refund the previous bidder
      address payable[] memory bidderArray = new address payable[](1);
      bidderArray[0] = previousBidder;
      uint256[] memory previousBidArray = new uint256[](1);
      previousBidArray[0] = previousBid;
      _pushPayments(bidderArray, previousBidArray);

      // When a bid outbids another, check to see if a time extension should apply.
      // We confirmed that the auction has not ended, so endTime is always >= the current timestamp.
      // Current time plus extension duration (always 15 mins) cannot overflow
      uint256 extensionWindow = isStandardAuction
        ? STANDARD_EXTENSION_WINDOW
        : auctionAdditionalConfigurations.extensionWindow;
      uint256 endTimeWithExtension = block.timestamp + extensionWindow;
      if (auctionDetails.end < endTimeWithExtension) {
        auctionDetails.end = endTimeWithExtension;
        auctionDetails.end = auctionDetails.end;
      }
    }

    emit AuctionSellingAgreementBidPlaced(
      auctionId,
      msg.sender,
      bid,
      auctionDetails.end
    );
  }

  /**
   * @dev see {IExchangeArtNFTMarketAuction - settleAuctionSellingAgreement}
   */
  function settleAuctionSellingAgreement(uint256 auctionId) public payable {
    AuctionBasicState memory auction = auctionIdToAuctionBasicState[auctionId];
    IERC721 nftContract = IERC721(auction.nftContract);

    auction.mustExist();
    auction.mustHaveEnded(block.timestamp);
    auction.mustHaveAtLeastOneBid();
    auction.mustBeReedemedByOwnerOrHighestBidder(msg.sender);

    // Remove the auction.
    delete nftContractToTokenIdToAuctionId[auction.nftContract][
      auction.tokenId
    ];
    delete auctionIdToAuctionBasicState[auctionId];
    if (!auction.isStandardAuction) {
      delete auctionIdToAuctioAdditionalConfigurations[auctionId];
    }

    nftContract.transferFrom(
      address(this),
      auction.highestBidder,
      auction.tokenId
    );

    //Distribute revenue for this sale.
    _handlePayments(
      auction.nftContract,
      auction.tokenId,
      auction.reservePriceOrHighestBid,
      auction.seller,
      auction.isPrimarySale
    );

    emit AuctionSellingAgreementSettled(
      auctionId,
      auction.seller,
      auction.highestBidder,
      auction.reservePriceOrHighestBid
    );
  }

  /**
   * @notice Returns the minimum amount a bidder must spend to participate in an auction at this particular moment in time.
   * Bids must be greater than or equal to this value or they will revert.
   * @param auctionId The id of the auction to check.
   * @return minimum The minimum amount for a bid to be accepted.
   */
  function getMinBidAmount(
    uint256 auctionId
  ) public view returns (uint256 minimum) {
    // todo optimize this by sending values as parameters
    AuctionBasicState storage auctionDetails = auctionIdToAuctionBasicState[
      auctionId
    ];
    AuctionAdditionalConfiguration
      storage auctionAdditionalConfiguration = auctionIdToAuctioAdditionalConfigurations[
        auctionId
      ];

    if (auctionDetails.end == 0) {
      return auctionDetails.reservePriceOrHighestBid;
    }
    uint256 endingPhase = auctionDetails.isStandardAuction
      ? STANDARD_ENDING_PHASE
      : auctionAdditionalConfiguration.endingPhase;
    uint256 endingPhasePercentageFlip = auctionDetails.isStandardAuction
      ? STANDARD_ENDING_PHASE
      : auctionAdditionalConfiguration.endingPhasePercentageFlip;

    if (block.timestamp >= auctionDetails.end - endingPhase) {
      // In the ending phase
      uint256 percentageBasedBid = auctionDetails.reservePriceOrHighestBid +
        (endingPhasePercentageFlip * auctionDetails.reservePriceOrHighestBid) /
        100;
      uint256 minIncrementBasedBid = auctionDetails.reservePriceOrHighestBid +
        auctionDetails.minimumIncrement;
      if (percentageBasedBid > minIncrementBasedBid) {
        minimum = percentageBasedBid;
      } else {
        minimum = minIncrementBasedBid;
      }
    } else {
      minimum =
        auctionDetails.reservePriceOrHighestBid +
        auctionDetails.minimumIncrement;
    }
  }

  // /**
  //  * @notice Returns auction details for a given auctionId.
  //  * @param auctionId The id of the auction to lookup.
  //  */
  function getAuctionDetails(
    uint256 auctionId
  ) external view returns (AuctionState memory auction) {
    AuctionBasicState
      storage auctionStandardDetails = auctionIdToAuctionBasicState[auctionId];

    auction.reservePriceOrHighestBid = auctionStandardDetails
      .reservePriceOrHighestBid;
    auction.nftContract = auctionStandardDetails.nftContract;
    auction.minimumIncrement = auctionStandardDetails.minimumIncrement;
    auction.highestBidder = auctionStandardDetails.highestBidder;
    auction.seller = auctionStandardDetails.seller;
    auction.end = auctionStandardDetails.end;
    auction.isPrimarySale = auctionStandardDetails.isPrimarySale;
    auction.isStandardAuction = auctionStandardDetails.isStandardAuction;
    if (auctionStandardDetails.isStandardAuction) {
      auction.endingPhase = STANDARD_ENDING_PHASE;
      auction.endingPhasePercentageFlip = STANDARD_ENDING_PHASE_PERCENTAGE_FLIP;
      auction.extensionWindow = STANDARD_EXTENSION_WINDOW;
      auction.buyOutPrice = 0;
      auction.start = 0; // Standard auctions are reserved price triggered so don't have a start time
      auction.isReservePriceTriggered = true; // Standard auctions can only be reserved price triggered;
    } else {
      AuctionAdditionalConfiguration
        storage auctionAdditionalConfigurations = auctionIdToAuctioAdditionalConfigurations[
          auctionId
        ];
      auction.endingPhase = auctionAdditionalConfigurations.endingPhase;
      auction.endingPhasePercentageFlip = auctionAdditionalConfigurations
        .endingPhasePercentageFlip;
      auction.extensionWindow = auctionAdditionalConfigurations.extensionWindow;
      auction.buyOutPrice = auctionAdditionalConfigurations.buyOutPrice;
      auction.start = auctionAdditionalConfigurations.start;
      auction.isReservePriceTriggered = auctionAdditionalConfigurations
        .isReservePriceTriggered;
    }
  }

  /**
   * @notice Returns the auctionId for a given NFT, or 0 if no auction is found.
   * @dev If an auction is canceled, it will not be returned. However the auction may be over and pending finalization.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @return auctionId The id of the auction, or 0 if no auction is found.
   */
  function getReserveAuctionIdFor(
    address nftContract,
    uint256 tokenId
  ) external view returns (uint256 auctionId) {
    auctionId = nftContractToTokenIdToAuctionId[nftContract][tokenId];
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[1_000] private __gap;
}