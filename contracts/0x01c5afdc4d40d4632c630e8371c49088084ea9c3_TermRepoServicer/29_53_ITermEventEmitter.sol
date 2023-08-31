//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

import "./ITermAuctionEvents.sol";
import "./ITermAuctionBidLockerEvents.sol";
import "./ITermAuctionOfferLockerEvents.sol";
import "./ITermRepoCollateralManagerEvents.sol";
import "./ITermRepoServicerEvents.sol";
import "./ITermRepoRolloverManagerEvents.sol";
import "./ITermRepoLockerEvents.sol";
import "./ITermRepoTokenEvents.sol";
import "./ITermEventEmitterEvents.sol";
import "../lib/TermAuctionBid.sol";

interface ITermEventEmitter is
    ITermAuctionEvents,
    ITermAuctionBidLockerEvents,
    ITermAuctionOfferLockerEvents,
    ITermRepoCollateralManagerEvents,
    ITermRepoServicerEvents,
    ITermRepoRolloverManagerEvents,
    ITermRepoLockerEvents,
    ITermRepoTokenEvents,
    ITermEventEmitterEvents
{
    // ========================================================================
    // = TermAuction Events ===================================================
    // ========================================================================

    /// @param termRepoId The id of the current Term Repo deployment being initialized
    /// @param termAuctionId The id of the auction being initialized
    /// @param termAuction The address of the auction contract being initialized
    /// @param auctionEndTime The end time of the auction being initialized
    /// @param version The version tag of the smart contract deployed
    function emitTermAuctionInitialized(
        bytes32 termRepoId,
        bytes32 termAuctionId,
        address termAuction,
        uint256 auctionEndTime,
        string calldata version
    ) external;

    /// @param termAuctionId A Term Auction id
    /// @param id A bid id
    /// @param amount The amount assigned to this bid
    function emitBidAssigned(
        bytes32 termAuctionId,
        bytes32 id,
        uint256 amount
    ) external;

    /// @param termAuctionId A Term Auction id
    /// @param id An offer id
    /// @param amount The amount assigned to this offer
    function emitOfferAssigned(
        bytes32 termAuctionId,
        bytes32 id,
        uint256 amount
    ) external;

    /// @param termAuctionId The Term Auction id of auction completed
    /// @param timestamp The timestamp of the current block
    /// @param blockNumber The number of the current block
    /// @param totalAssignedBids The number of assigned bids in the auction
    /// @param totalAssignedOffers The number of assigned offers in the auction
    /// @param clearingPrice The clearing price of the auction
    function emitAuctionCompleted(
        bytes32 termAuctionId,
        uint256 timestamp,
        uint256 blockNumber,
        uint256 totalAssignedBids,
        uint256 totalAssignedOffers,
        uint256 clearingPrice
    ) external;

    /// @param nonViableAuction Auction not viable due to bid and offer prices not intersecting
    /// @param auctionCancelledforWithdrawal Auction has been cancelled for withdrawal
    function emitAuctionCancelled(
        bytes32 termAuctionId,
        bool nonViableAuction,
        bool auctionCancelledforWithdrawal
    ) external;

    /// @param termAuctionId The id of the auction paused
    /// @param termRepoId The Term Repo id associated with auction paused
    function emitCompleteAuctionPaused(
        bytes32 termAuctionId,
        bytes32 termRepoId
    ) external;

    /// @param termAuctionId The id of the auction unpaused
    /// @param termRepoId The Term Repo id associated with auction unpaused
    function emitCompleteAuctionUnpaused(
        bytes32 termAuctionId,
        bytes32 termRepoId
    ) external;

    // ========================================================================
    // = TermAuctionBidLocker Events ==========================================
    // ========================================================================

    /// @param termRepoId The Term Repo id associated with BidLocker initialized
    /// @param termAuctionId The Term Auction id associated with BidLocker initialized
    /// @param termAuctionBidLocker The address of the TermAuctionBidLocker contract being intialized
    /// @param auctionStartTime The time at which auction bids will be accepted for submission
    /// @param revealTime The time at which sealed auction bids can be revealed
    /// @param maxBidPrice The maximum tender price (interest rate) in percentage
    /// @param minimumTenderAmount The minimum amount of borrowed purchase token that will be accepted
    /// @param dayCountFractionMantissa The day count fraction remainder
    function emitTermAuctionBidLockerInitialized(
        bytes32 termRepoId,
        bytes32 termAuctionId,
        address termAuctionBidLocker,
        uint256 auctionStartTime,
        uint256 revealTime,
        uint256 maxBidPrice,
        uint256 minimumTenderAmount,
        uint256 dayCountFractionMantissa
    ) external;

    /// @param termAuctionId A Term Auction id
    /// @param bid A struct containing details of the locked bid
    /// @param referralAddress The address of the referrer. Zero Address if none.
    function emitBidLocked(
        bytes32 termAuctionId,
        TermAuctionBid calldata bid,
        address referralAddress
    ) external;

    /// @param termAuctionId A Term Auction id
    /// @param id The bid id
    /// @param bidPrice The revealed price of the bid
    function emitBidRevealed(
        bytes32 termAuctionId,
        bytes32 id,
        uint256 bidPrice
    ) external;

    /// @param termAuctionId A Term Auction id
    /// @param id A bid id
    function emitBidUnlocked(bytes32 termAuctionId, bytes32 id) external;

    /// @param termAuctionId A Term Auction id
    /// @param id A bid id
    function emitBidInShortfall(bytes32 termAuctionId, bytes32 id) external;

    /// @param termAuctionId The id of Term Auction where bid locking is paused
    /// @param termRepoId The Term Repo id where bid locking is paused
    function emitBidLockingPaused(
        bytes32 termAuctionId,
        bytes32 termRepoId
    ) external;

    /// @param termAuctionId The id of Term Auction where bid locking is unpaused
    /// @param termRepoId The Term Repo id where bid locking is unpaused
    function emitBidLockingUnpaused(
        bytes32 termAuctionId,
        bytes32 termRepoId
    ) external;

    /// @param termAuctionId The id of Term Auction where bid unlocking is paused
    /// @param termRepoId The Term Repo id where bid unlocking is paused
    function emitBidUnlockingPaused(
        bytes32 termAuctionId,
        bytes32 termRepoId
    ) external;

    /// @param termAuctionId The id of Term Auction where bid unlocking is unpaused
    /// @param termRepoId The Term Repo id where bid unlocking is unpaused
    function emitBidUnlockingUnpaused(
        bytes32 termAuctionId,
        bytes32 termRepoId
    ) external;

    // ========================================================================
    // = TermAuctionOfferLocker Events ========================================
    // ========================================================================

    /// @param termRepoId The Term Repo id associated with OfferLocker initialized
    /// @param termAuctionId The Term Auction id associated with OfferLocker initialized
    /// @param termAuctionOfferLocker The address of the TermAuctionOfferLocker contract being intialized
    /// @param auctionStartTime The time at which auction bids will be accepted for submission
    /// @param revealTime The time at which sealed auction bids can be revealed
    function emitTermAuctionOfferLockerInitialized(
        bytes32 termRepoId,
        bytes32 termAuctionId,
        address termAuctionOfferLocker,
        uint256 auctionStartTime,
        uint256 revealTime,
        uint256 maxOfferPrice,
        uint256 minimumTenderAmount
    ) external;

    /// @param termAuctionId A Term Auction id
    /// @param id An offer id
    /// @param offeror The address of the offeror
    /// @param offerPrice The offer price
    /// @param amount The amount of purchase tokens offered
    /// @param purchaseToken The address of the purchase token being offered
    /// @param referralAddress The address of the referrer. Zero Address if none.
    function emitOfferLocked(
        bytes32 termAuctionId,
        bytes32 id,
        address offeror,
        bytes32 offerPrice,
        uint256 amount,
        address purchaseToken,
        address referralAddress
    ) external;

    /// @param termAuctionId A Term Auction id
    /// @param id An offer id
    /// @param offerPrice The offer price revealed
    function emitOfferRevealed(
        bytes32 termAuctionId,
        bytes32 id,
        uint256 offerPrice
    ) external;

    /// @param termAuctionId A Term Auction id
    /// @param id An offer id
    function emitOfferUnlocked(bytes32 termAuctionId, bytes32 id) external;

    /// @param termAuctionId The id of Term Auction where offer locking is paused
    /// @param termRepoId The Term Repo id where offer locking is paused
    function emitOfferLockingPaused(
        bytes32 termAuctionId,
        bytes32 termRepoId
    ) external;

    /// @param termAuctionId The id of Term Auction where offer locking is unpaused
    /// @param termRepoId The Term Repo id where offer locking is unpaused
    function emitOfferLockingUnpaused(
        bytes32 termAuctionId,
        bytes32 termRepoId
    ) external;

    /// @param termAuctionId The id of Term Auction where offer unlocking is paused
    /// @param termRepoId The Term Repo id where offer unlocking is paused
    function emitOfferUnlockingPaused(
        bytes32 termAuctionId,
        bytes32 termRepoId
    ) external;

    /// @param termAuctionId The id of Term Auction where offer unlocking is unpaused
    /// @param termRepoId The Term Repo id where offer unlocking is unpaused
    function emitOfferUnlockingUnpaused(
        bytes32 termAuctionId,
        bytes32 termRepoId
    ) external;

    // ========================================================================
    // = TermRepoCollateralManager Events =========================================
    // ========================================================================

    /// @param termRepoId The Term Repo id associated with collateral manger being initialized
    /// @param termRepoCollateralManager The address of the TermRepoCollateralManager contract being intialized
    /// @param collateralTokens An array containing a list of the addresses of all accepted collateral tokens
    /// @param initialCollateralRatios An array containing the initial collateral ratios for each collateral token
    /// @param maintenanceCollateralRatios An array containing the maintenance collateral ratios for each collateral token
    /// @param liquidatedDamagesSchedule An array containing the liquidated damages applicable to each collateral token
    function emitTermRepoCollateralManagerInitialized(
        bytes32 termRepoId,
        address termRepoCollateralManager,
        address[] calldata collateralTokens,
        uint256[] calldata initialCollateralRatios,
        uint256[] calldata maintenanceCollateralRatios,
        uint256[] calldata liquidatedDamagesSchedule
    ) external;

    /// @param termRepoId The Term Repo id for the Term Repo being reopened
    /// @param termRepoCollateralManager The TermRepoCollateralManager address for the Term Repo being reopened
    /// @param termAuctionBidLocker New TermAuctionBidLocker to be paired for reopening
    function emitPairReopeningBidLocker(
        bytes32 termRepoId,
        address termRepoCollateralManager,
        address termAuctionBidLocker
    ) external;

    /// @param termRepoId A Term Repo id
    /// @param borrower The address of the borrower
    /// @param collateralToken The address of the collateral token locked
    /// @param amount The amount of collateral being locked
    function emitCollateralLocked(
        bytes32 termRepoId,
        address borrower,
        address collateralToken,
        uint256 amount
    ) external;

    /// @param termRepoId A Term Repo id
    /// @param borrower The address of the borrower
    /// @param collateralToken The address of the collateral token locked
    /// @param amount The amount of collateral being unlocked
    function emitCollateralUnlocked(
        bytes32 termRepoId,
        address borrower,
        address collateralToken,
        uint256 amount
    ) external;

    /// @param termRepoId A Term Repo id
    /// @param borrower The address of the borrower
    /// @param liquidator The address of the liquidator
    /// @param closureAmount The amount of repurchase exposure covered
    /// @param collateralToken The address of the collateral tokens liquidated
    /// @param amountLiquidated The amount of collateral tokens liquidated
    function emitLiquidation(
        bytes32 termRepoId,
        address borrower,
        address liquidator,
        uint256 closureAmount,
        address collateralToken,
        uint256 amountLiquidated,
        uint256 protocolSeizureAmount,
        bool defaultLiquidation
    ) external;

    /// @param termRepoId The id of Term Repo where liquidations are paused
    function emitLiquidationPaused(bytes32 termRepoId) external;

    /// @param termRepoId The id of Term Repo where liquidation is unpaused
    function emitLiquidationUnpaused(bytes32 termRepoId) external;

    // ========================================================================
    // = TermRepoServicer Events ===============================================
    // ========================================================================

    /// @param termRepoId The Term Repo id associated with TermRepoServicer being initialized
    /// @param termRepoServicer The address of the TermRepoServicer contract being initialized
    /// @param purchaseToken The address of the purchase token
    /// @param maturityTimestamp The time at which repurchase is due
    /// @param endOfRepurchaseWindow The time at which the repurchase window ends
    /// @param redemptionTimestamp The time when redemption of Term Repo Tokens begins
    /// @param servicingFee percentage share of bid amounts charged to bidder
    /// @param version The version tag of the smart contract deployed
    function emitTermRepoServicerInitialized(
        bytes32 termRepoId,
        address termRepoServicer,
        address purchaseToken,
        uint256 maturityTimestamp,
        uint256 endOfRepurchaseWindow,
        uint256 redemptionTimestamp,
        uint256 servicingFee,
        string calldata version
    ) external;

    /// @param termRepoId The Term Repo id for the Term Repo being reopened
    /// @param termRepoServicer The address of the TermRepoServicer contract for the Term Repo being reopened
    /// @param termAuctionOfferLocker The TermAuctionOfferLocker to be paired for reopening
    /// @param termAuction The address of the TermAuction contract to be paired for reopening
    function emitReopeningOfferLockerPaired(
        bytes32 termRepoId,
        address termRepoServicer,
        address termAuctionOfferLocker,
        address termAuction
    ) external;

    /// @param termRepoId A Term Repo id
    /// @param offeror The address of the offeror
    /// @param amount The offer amount to be locked
    /// @notice This event is not to be confused with OfferLocked by TermOfferLocker
    /// @notice Both will be triggered, this one specifically refers to corresponding action taken by Term Servicer
    function emitOfferLockedByServicer(
        bytes32 termRepoId,
        address offeror,
        uint256 amount
    ) external;

    /// @param termRepoId A Term Repo id
    /// @param offeror The address of the offeror
    /// @param amount The offer amount to be unlocked
    /// @notice This event is not to be confused with OfferUnlocked by TermOfferLocker
    /// @notice Both will be triggered, this one specifically refers to corresponding action taken by Term Servicer
    function emitOfferUnlockedByServicer(
        bytes32 termRepoId,
        address offeror,
        uint256 amount
    ) external;

    /// @param offerId Unique id for offer
    /// @param offeror The address of the offeror
    /// @param purchasePrice The offer amount fulfilled
    /// @param repurchasePrice The repurchase price due to offeror at maturity
    /// @param repoTokensMinted The amount of Term Repo Tokens minted to offeror
    function emitOfferFulfilled(
        bytes32 offerId,
        address offeror,
        uint256 purchasePrice,
        uint256 repurchasePrice,
        uint256 repoTokensMinted
    ) external;

    /// @param termRepoId A Term Repo id
    /// @param redeemer The address of the redeemer
    /// @param redemptionAmount The amount of TermRepoTokens redeemed
    /// @param redemptionHaircut The haircut applied to redemptions (if any) due to unrecoverable repo exposure
    function emitTermRepoTokensRedeemed(
        bytes32 termRepoId,
        address redeemer,
        uint256 redemptionAmount,
        uint256 redemptionHaircut
    ) external;

    /// @param termRepoId A Term Repo id
    /// @param bidder The address of the bidder
    /// @param purchasePrice The bid amount fulfilled in auction
    /// @param repurchasePrice The repurchase price due at maturity
    /// @param servicingFees The fees earned by the protocol
    function emitBidFulfilled(
        bytes32 termRepoId,
        address bidder,
        uint256 purchasePrice,
        uint256 repurchasePrice,
        uint256 servicingFees
    ) external;

    /// @param termRepoId A Term Repo id
    /// @param borrower The address of the borrower
    /// @param purchasePrice The purchase price received from new TermRepo
    /// @param repurchasePrice The new repurchase price due at maturity of new TermRepo
    /// @param servicingFees The fees earned by the protocol
    function emitExposureOpenedOnRolloverNew(
        bytes32 termRepoId,
        address borrower,
        uint256 purchasePrice,
        uint256 repurchasePrice,
        uint256 servicingFees
    ) external;

    /// @param termRepoId A Term Repo id
    /// @param borrower The address of the borrower
    /// @param amountRolled The repurchase exposure balance closed on old Term Repo
    function emitExposureClosedOnRolloverExisting(
        bytes32 termRepoId,
        address borrower,
        uint256 amountRolled
    ) external;

    /// @param termRepoId A Term Repo id
    /// @param borrower The address of the borrower
    /// @param amount The amount submitted for repurchase
    function emitRepurchasePaymentSubmitted(
        bytes32 termRepoId,
        address borrower,
        uint256 amount
    ) external;

    /// @param termRepoId A Term Repo id
    /// @param minter The address of the minter
    /// @param netTokensReceived The amount of Term Repo Tokens received by minter net of servicing fees
    /// @param servicingFeeTokens The number of Term Repo Tokens retained by protocol in servicing fees
    /// @param repurchasePrice The repurchase exposure opened by minter against Term Repo Token mint
    function emitMintExposure(
        bytes32 termRepoId,
        address minter,
        uint256 netTokensReceived,
        uint256 servicingFeeTokens,
        uint256 repurchasePrice
    ) external;

    /// @param termRepoId A Term Repo id
    /// @param borrower The address of the borrower
    /// @param closeAmount The amount of repurchase exposure to close
    function emitBurnCollapseExposure(
        bytes32 termRepoId,
        address borrower,
        uint256 closeAmount
    ) external;

    // ========================================================================
    // = TermRepoRolloverManager Events ===========================================
    // ========================================================================

    /// @param termRepoId The Term Repo id associated with TermRepoRolloverManager being initialized
    /// @param rolloverManager The address of the TermRepoRolloverManager contract being initialized
    function emitTermRepoRolloverManagerInitialized(
        bytes32 termRepoId,
        address rolloverManager
    ) external;

    /// @param termRepoId The Term Repo id of existing Term Repo
    /// @param rolloverTermAuctionId The Term Auction Id that rollover bid will be submitted into
    function emitRolloverTermApproved(
        bytes32 termRepoId,
        bytes32 rolloverTermAuctionId
    ) external;

    /// @param termRepoId The Term Repo id of existing Term Repo
    /// @param rolloverTermAuctionId The Term Auction Id whose rollover approval is revoked
    function emitRolloverTermApprovalRevoked(
        bytes32 termRepoId,
        bytes32 rolloverTermAuctionId
    ) external;

    /// @param termRepoId The Term Repo id of existing Term Repo
    /// @param rolloverTermRepoId Term Repo Id of Rollover Term Repo
    /// @param borrower The address of the borrower
    /// @param rolloverAuction The address of the auction being rolled over to
    /// @param rolloverAmount The repurchase amount being rolled over
    /// @param hashedBidPrice The hash of the rollover bid price
    function emitRolloverElection(
        bytes32 termRepoId,
        bytes32 rolloverTermRepoId,
        address borrower,
        address rolloverAuction,
        uint256 rolloverAmount,
        bytes32 hashedBidPrice
    ) external;

    /// @param termRepoId The Term Repo id of existing Term Repo
    /// @param borrower The address of the borrower
    function emitRolloverCancellation(
        bytes32 termRepoId,
        address borrower
    ) external;

    /// @param termRepoId The Term Repo id of existing Term Repo
    /// @param borrower The address of the borrower
    function emitRolloverBidLockSucceeded(
        bytes32 termRepoId,
        address borrower
    ) external;

    /// @param termRepoId The Term Repo id of existing Term Repo
    /// @param borrower The address of the borrower
    function emitRolloverBidLockFailed(
        bytes32 termRepoId,
        address borrower
    ) external;

    /// @param termRepoId The Term Repo id of existing Term Repo
    /// @param borrower The address of the borrower
    function emitRolloverProcessed(
        bytes32 termRepoId,
        address borrower
    ) external;

    // ========================================================================
    // = TermRepoLocker Events ======================================================
    // ========================================================================

    /// @param termRepoId The Term Repo id associated with TermRepoLocker contract being initialized
    /// @param termRepoLocker The address of the TermRepoLocker contract being initialized
    function emitTermRepoLockerInitialized(
        bytes32 termRepoId,
        address termRepoLocker
    ) external;

    /// @param termRepoId A Term Repo id
    function emitTermRepoLockerTransfersPaused(bytes32 termRepoId) external;

    /// @param termRepoId A Term Repo id
    function emitTermRepoLockerTransfersUnpaused(bytes32 termRepoId) external;

    // ========================================================================
    // = TermRepoToken Events =====================================================
    // ========================================================================

    /// @param termRepoId The Term Repo id associated with the TermRepoToken being initalized
    /// @param termRepoToken The address of the TermRepoToken contract being initialized
    /// @param redemptionRatio The number of purchase tokens redeemable per unit of Term Repo Token at par
    function emitTermRepoTokenInitialized(
        bytes32 termRepoId,
        address termRepoToken,
        uint256 redemptionRatio
    ) external;

    /// @param termRepoId The Term Repo id associated with the TermRepoToken where minting is paused
    function emitTermRepoTokenMintingPaused(bytes32 termRepoId) external;

    /// @param termRepoId The Term Repo id associated with the TermRepoToken where minting is unpaused
    function emitTermRepoTokenMintingUnpaused(bytes32 termRepoId) external;

    /// @param termRepoId The Term Repo id associated with the TermRepoToken where burning is paused
    function emitTermRepoTokenBurningPaused(bytes32 termRepoId) external;

    /// @param termRepoId The Term Repo id associated with the TermRepoToken where burning is unpaused
    function emitTermRepoTokenBurningUnpaused(bytes32 termRepoId) external;

    // ========================================================================
    // = TermEventEmitter Events ==============================================
    // ========================================================================

    /// @param termRepoId The id of the Term Repo being delisted
    function emitDelistTermRepo(bytes32 termRepoId) external;

    /// @param termAuctionId The id of the Term Auction being delisted
    function emitDelistTermAuction(bytes32 termAuctionId) external;
}