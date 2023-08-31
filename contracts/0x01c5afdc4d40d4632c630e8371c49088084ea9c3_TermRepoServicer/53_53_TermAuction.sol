//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

import "./interfaces/ITermAuctionBidLocker.sol";
import "./interfaces/ITermAuctionErrors.sol";
import "./interfaces/ITermAuctionOfferLocker.sol";
import "./interfaces/ITermEventEmitter.sol";
import "./interfaces/ITermRepoCollateralManager.sol";
import "./interfaces/ITermRepoServicer.sol";

import "./lib/CompleteAuctionInput.sol";

import "./lib/ExponentialNoError.sol";
import "./lib/TermAuctionRevealedBid.sol";
import "./lib/TermAuctionRevealedOffer.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/// @author TermLabs
/// @title Term Auction
/// @notice This contract calculates a clearing price in a blind double auction and manages auction clearing and settlement
/// @dev This contract belongs to the Term Auction group of contracts and is specific to a Term Repo deployment
contract TermAuction is
    ITermAuctionErrors,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    ExponentialNoError
{
    // ========================================================================
    // = Structs  =============================================================
    // ========================================================================
    /// State used during the `calculateClearingPrice` function
    /// @dev Used to reduce the number of stack variables
    struct ClearingPriceState {
        // Variables describing current loop iteration
        uint256 offerPrice; // p^o_i
        uint256 offerIndex; // idxo(p^o_i)
        uint256 bidIndex; // idxb(p^o_i)
        uint256 cumSumOffers; // cso(p^o_i)
        uint256 cumSumBids; // csb(p^o_i)
        uint256 maxClearingVolume; // maxcv_i
        // Variables describing next loop iteration
        uint256 nextOfferIndex;
        uint256 nextBidIndex;
        uint256 nextCumSumOffers;
        uint256 nextCumSumBids;
        uint256 nextOfferPrice;
        uint256 nextMaxClearingVolume;
        // Auxiliary variables
        bool minCumSumCorrection; // Minimisation correction indicator
        uint256 nextBidPrice; // Next bid price in minimisation
        // Principal quantities of interest
        uint256 clearingPrice; // p_c
    }

    // ========================================================================
    // = Constants  ===========================================================
    // ========================================================================
    uint256 public constant CLEARING_PRICE_POST_PROCESSING_OFFSET = uint256(1);
    uint256 public constant THREESIXTY_DAYCOUNT_SECONDS = 360 days;

    // ========================================================================
    // = Access Roles  ========================================================
    // ========================================================================
    bytes32 public constant INITIALIZER_ROLE = keccak256("INITIALIZER_ROLE");

    // ========================================================================
    // = State Variables  =====================================================
    // ========================================================================

    // Auction configuration.
    bytes32 public termRepoId;
    bytes32 public termAuctionId;
    uint256 public auctionEndTime;
    uint256 public dayCountFractionMantissa;
    ITermRepoServicer public termRepoServicer;
    ITermAuctionBidLocker public termAuctionBidLocker;
    ITermAuctionOfferLocker public termAuctionOfferLocker;
    IERC20MetadataUpgradeable public purchaseToken;
    ITermEventEmitter internal emitter;

    // Completed auction state
    uint256 public clearingPrice;
    bool public auctionCompleted;
    bool public auctionCancelledForWithdrawal;
    bool public completeAuctionPaused;
    bool internal termContractPaired;

    // ========================================================================
    // = Modifiers  ===========================================================
    // ========================================================================

    /// @notice This only runs if the auction is closed (after auction end time)
    /// @dev This uses the block timestamp to determine if the auction is closed
    modifier onlyWhileAuctionClosed() {
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp <= auctionEndTime) {
            revert AuctionNotClosed();
        }
        _;
    }

    modifier whenCompleteAuctionNotPaused() {
        if (completeAuctionPaused) {
            revert CompleteAuctionPaused();
        }
        _;
    }

    modifier notTermContractPaired() {
        if (termContractPaired) {
            revert AlreadyTermContractPaired();
        }
        termContractPaired = true;
        _;
    }

    // ========================================================================
    // = Deploy (https://docs.openzeppelin.com/contracts/4.x/upgradeable) =
    // ========================================================================

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// Initializes the contract
    /// @dev See: https://docs.openzeppelin.com/contracts/4.x/upgradeable
    function initialize(
        string calldata termRepoId_,
        string calldata auctionId_,
        uint256 auctionEndTime_,
        uint256 termStart_,
        uint256 redemptionTimestamp_,
        IERC20MetadataUpgradeable purchaseToken_
    ) external initializer {
        UUPSUpgradeable.__UUPSUpgradeable_init();
        AccessControlUpgradeable.__AccessControl_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(INITIALIZER_ROLE, msg.sender);

        termRepoId = keccak256(abi.encodePacked(termRepoId_));
        termAuctionId = keccak256(abi.encodePacked(auctionId_));

        auctionEndTime = auctionEndTime_;
        dayCountFractionMantissa =
            ((redemptionTimestamp_ - termStart_) * expScale) /
            THREESIXTY_DAYCOUNT_SECONDS;
        purchaseToken = purchaseToken_;
        auctionCompleted = false;
        termContractPaired = false;
        auctionCancelledForWithdrawal = false;
    }

    function pairTermContracts(
        ITermEventEmitter emitter_,
        ITermRepoServicer termRepoServicer_,
        ITermAuctionBidLocker termAuctionBidLocker_,
        ITermAuctionOfferLocker termAuctionOfferLocker_,
        string calldata version_
    ) external onlyRole(INITIALIZER_ROLE) notTermContractPaired {
        emitter = emitter_;

        termRepoServicer = termRepoServicer_;
        termAuctionBidLocker = termAuctionBidLocker_;
        termAuctionOfferLocker = termAuctionOfferLocker_;

        emitter.emitTermAuctionInitialized(
            termRepoId,
            termAuctionId,
            address(this),
            auctionEndTime,
            version_
        );
    }

    // ========================================================================
    // = Interface/API ========================================================
    // ========================================================================

    /// @notice Calculates an auction's clearing price, assigns bids/offers, and returns unassigned funds
    /// @param completeAuctionInput A struct containing all revealed and unrevealed bids and offers and expired rollover bids
    function completeAuction(
        CompleteAuctionInput calldata completeAuctionInput
    ) external onlyWhileAuctionClosed whenCompleteAuctionNotPaused {
        if (auctionCompleted) {
            revert AuctionAlreadyCompleted();
        }
        if (auctionCancelledForWithdrawal) {
            revert AuctionCancelledForWithdrawal();
        }
        auctionCompleted = true;

        // Sort bids/offers by price. Orders right on the price
        // edge will be partially filled.
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            if (
                completeAuctionInput.unrevealedBidSubmissions.length > 0 ||
                completeAuctionInput.unrevealedOfferSubmissions.length > 0
            ) {
                revert InvalidParameters(
                    "All tender prices must be revealed for auction to be complete"
                );
            }
        }

        (
            TermAuctionRevealedBid[] memory sortedBids,
            TermAuctionBid[] memory unrevealedBids
        ) = termAuctionBidLocker.getAllBids(
                completeAuctionInput.revealedBidSubmissions,
                completeAuctionInput.expiredRolloverBids,
                completeAuctionInput.unrevealedBidSubmissions
            );
        (
            TermAuctionRevealedOffer[] memory sortedOffers,
            TermAuctionOffer[] memory unrevealedOffers
        ) = termAuctionOfferLocker.getAllOffers(
                completeAuctionInput.revealedOfferSubmissions,
                completeAuctionInput.unrevealedOfferSubmissions
            );

        // Calculate a clearing price only if both bids and offers exist and market intersects
        if (
            sortedBids.length > 0 &&
            sortedOffers.length > 0 &&
            sortedBids[sortedBids.length - 1].bidPriceRevealed >=
            sortedOffers[0].offerPriceRevealed
        ) {
            (
                ,
                // uint256 clearingPrice_
                uint256 maxAssignable
            ) = _calculateAndStoreClearingPrice(sortedBids, sortedOffers);

            uint256 purchaseTokenDecimals = purchaseToken.decimals();

            // Process revealed bids/offers
            uint256 totalAssignedBids = _assignBids(
                sortedBids,
                maxAssignable,
                purchaseTokenDecimals
            );
            uint256 totalAssignedOffers = _assignOffers(
                sortedOffers,
                maxAssignable,
                purchaseTokenDecimals
            );

            emitter.emitAuctionCompleted(
                termAuctionId, // solhint-disable-next-line not-rely-on-time
                block.timestamp,
                block.number,
                totalAssignedBids,
                totalAssignedOffers,
                clearingPrice
            );
        } else {
            // Return sorted bid funds.
            for (uint256 i = 0; i < sortedBids.length; ++i) {
                if (sortedBids[i].isRollover) {
                    _markRolloverAsProcessed(
                        sortedBids[i].rolloverPairOffTermRepoServicer,
                        sortedBids[i].bidder
                    );
                } else {
                    termAuctionBidLocker.auctionUnlockBid(
                        sortedBids[i].id,
                        sortedBids[i].bidder,
                        sortedBids[i].collateralTokens,
                        sortedBids[i].collateralAmounts
                    );
                }
            }
            // Return sorted offer funds.
            for (uint256 i = 0; i < sortedOffers.length; ++i) {
                termAuctionOfferLocker.unlockOfferPartial(
                    sortedOffers[i].id,
                    sortedOffers[i].offeror,
                    sortedOffers[i].amount
                );
            }

            if (
                sortedBids.length > 0 &&
                sortedOffers.length > 0 &&
                sortedBids[sortedBids.length - 1].bidPriceRevealed <
                sortedOffers[0].offerPriceRevealed
            ) {
                emitter.emitAuctionCancelled(termAuctionId, true, false);
            } else {
                emitter.emitAuctionCancelled(termAuctionId, false, false);
            }
        }

        // Return unrevealed bid funds.
        for (uint256 i = 0; i < unrevealedBids.length; ++i) {
            if (unrevealedBids[i].isRollover) {
                _markRolloverAsProcessed(
                    unrevealedBids[i].rolloverPairOffTermRepoServicer,
                    unrevealedBids[i].bidder
                );
            } else {
                termAuctionBidLocker.auctionUnlockBid(
                    unrevealedBids[i].id,
                    unrevealedBids[i].bidder,
                    unrevealedBids[i].collateralTokens,
                    unrevealedBids[i].collateralAmounts
                );
            }
        }
        // Return unrevealed offer funds.
        for (uint256 i = 0; i < unrevealedOffers.length; ++i) {
            termAuctionOfferLocker.unlockOfferPartial(
                unrevealedOffers[i].id,
                unrevealedOffers[i].offeror,
                unrevealedOffers[i].amount
            );
        }

        assert(termRepoServicer.isTermRepoBalanced());
    }

    // ========================================================================
    // = Admin ================================================================
    // ========================================================================

    /// @notice Cancels an auction and returns all funds to bidders and fulfillBiders
    /// @param completeAuctionInput A struct containing all revealed and unrevealed bids and offers and expired rollover bids
    function cancelAuction(
        CompleteAuctionInput calldata completeAuctionInput
    ) public onlyWhileAuctionClosed onlyRole(DEFAULT_ADMIN_ROLE) {
        // Sort bids/offers by price. Orders right on the price
        // edge will be partially filled.
        (
            TermAuctionRevealedBid[] memory sortedBids,
            TermAuctionBid[] memory unrevealedBids
        ) = termAuctionBidLocker.getAllBids(
                completeAuctionInput.revealedBidSubmissions,
                completeAuctionInput.expiredRolloverBids,
                completeAuctionInput.unrevealedBidSubmissions
            );
        (
            TermAuctionRevealedOffer[] memory sortedOffers,
            TermAuctionOffer[] memory unrevealedOffers
        ) = termAuctionOfferLocker.getAllOffers(
                completeAuctionInput.revealedOfferSubmissions,
                completeAuctionInput.unrevealedOfferSubmissions
            );

        // Return revealed bid funds.
        uint256 i = 0;
        for (i = 0; i < sortedBids.length; ++i) {
            if (sortedBids[i].isRollover) {
                _markRolloverAsProcessed(
                    sortedBids[i].rolloverPairOffTermRepoServicer,
                    sortedBids[i].bidder
                );
            } else {
                termAuctionBidLocker.auctionUnlockBid(
                    sortedBids[i].id,
                    sortedBids[i].bidder,
                    sortedBids[i].collateralTokens,
                    sortedBids[i].collateralAmounts
                );
            }
        }
        // Return revealed offer funds.
        for (i = 0; i < sortedOffers.length; ++i) {
            termAuctionOfferLocker.unlockOfferPartial(
                sortedOffers[i].id,
                sortedOffers[i].offeror,
                sortedOffers[i].amount
            );
        }
        // Return unrevealed bid funds.
        for (i = 0; i < unrevealedBids.length; ++i) {
            if (unrevealedBids[i].isRollover) {
                _markRolloverAsProcessed(
                    unrevealedBids[i].rolloverPairOffTermRepoServicer,
                    unrevealedBids[i].bidder
                );
            } else {
                termAuctionBidLocker.auctionUnlockBid(
                    unrevealedBids[i].id,
                    unrevealedBids[i].bidder,
                    unrevealedBids[i].collateralTokens,
                    unrevealedBids[i].collateralAmounts
                );
            }
        }
        // Return unrevealed offer funds.
        for (i = 0; i < unrevealedOffers.length; ++i) {
            termAuctionOfferLocker.unlockOfferPartial(
                unrevealedOffers[i].id,
                unrevealedOffers[i].offeror,
                unrevealedOffers[i].amount
            );
        }

        emitter.emitAuctionCancelled(termAuctionId, false, false);

        assert(termRepoServicer.isTermRepoBalanced());
    }

    /// @notice Cancels an auction and sets auctionCancelledForWithdrawal to true to open unlocking tenders
    function cancelAuctionForWithdrawal(
        address[] calldata rolloverBorrowers,
        address[] calldata rolloverPairOffTermRepoServicer
    ) public onlyWhileAuctionClosed onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < rolloverBorrowers.length; ++i) {
            _markRolloverAsProcessed(
                rolloverPairOffTermRepoServicer[i],
                rolloverBorrowers[i]
            );
        }

        auctionCancelledForWithdrawal = true;
        emitter.emitAuctionCancelled(
            termAuctionId,
            false,
            auctionCancelledForWithdrawal
        );
    }

    // ========================================================================
    // = Helpers ==============================================================
    // ========================================================================
    function _increaseCumSumBids(
        TermAuctionRevealedBid[] memory sortedBids,
        uint256 startIndex,
        uint256 previousCumSumBids,
        uint256 currentPrice
    ) internal pure returns (uint256, uint256) {
        uint256 cumsumBids = previousCumSumBids;
        uint256 i;

        for (
            i = startIndex;
            sortedBids[i].bidPriceRevealed >= currentPrice;
            --i
        ) {
            cumsumBids += sortedBids[i].amount;
            if (i == 0) break;
        }
        return (
            cumsumBids,
            sortedBids[i].bidPriceRevealed < currentPrice ? i + 1 : i
        );
    }

    function _decreaseCumSumBids(
        TermAuctionRevealedBid[] memory sortedBids,
        uint256 startIndex,
        uint256 previousCumSumBids,
        uint256 currentPrice
    ) internal pure returns (uint256, uint256) {
        uint256 cumsumBids = previousCumSumBids;
        uint256 i;

        for (
            i = startIndex;
            i < sortedBids.length &&
                sortedBids[i].bidPriceRevealed < currentPrice;
            i++
        ) cumsumBids -= sortedBids[i].amount;

        return (cumsumBids, i);
    }

    /// Returns the min of two `uint256` values
    /// @param a The first value to compare
    /// @param b The second value to compare
    /// @return The min of the two values
    function _minUint256(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a >= b) {
            return b;
        } else {
            return a;
        }
    }

    /// Calculates the intersection between bid/offer schedules to arrive at a clearing price
    /// @dev Imagine a graph with price along the X-axis and cumsum(bid/offerAmount*price) along the Y-axis. This function finds the point where the supply line crosses the demand line using binary search
    /// @param sortedBids A sorted array of bids used to arrive at a demand schedule
    /// @param sortedOffers A sorted array of offers used to arrive at a supply schedule
    /// @param clearingOffset The offset to apply to the marginal bid and offer indexes when calculating the final clearing price
    /// @return clearingPrice The price at which Term Auction will be cleared
    function _calculateClearingPrice(
        TermAuctionRevealedBid[] memory sortedBids,
        TermAuctionRevealedOffer[] memory sortedOffers,
        uint256 clearingOffset
    ) internal pure returns (uint256, uint256) {
        if (clearingOffset != 1 && clearingOffset != 0) {
            revert ClearingOffsetNot0Or1(clearingOffset);
        }

        // Local function variables are kept in memory
        ClearingPriceState memory state = ClearingPriceState({
            offerPrice: sortedOffers[0].offerPriceRevealed, // p^o_i
            offerIndex: 1, // idxo(offerPrice)
            cumSumOffers: sortedOffers[0].amount, // cso(offerPrice)
            bidIndex: sortedBids.length,
            cumSumBids: 0,
            maxClearingVolume: 0,
            nextOfferIndex: 0,
            nextBidIndex: 0,
            nextCumSumOffers: 0,
            nextCumSumBids: 0,
            nextOfferPrice: 0,
            nextMaxClearingVolume: 0,
            minCumSumCorrection: false,
            nextBidPrice: 0,
            clearingPrice: 0
        });

        // Calculate bidIndex = idxb(offerPrice) and cumSumBids = csb(offerPrice)
        (state.cumSumBids, state.bidIndex) = _increaseCumSumBids(
            sortedBids,
            state.bidIndex - 1,
            0,
            state.offerPrice
        );

        // Calculate initial maximal clearing volume
        state.maxClearingVolume = _minUint256(
            state.cumSumBids,
            state.cumSumOffers
        );

        // Calculate the pre-clearance price: maximise the clearing volume
        while (
            state.offerIndex < sortedOffers.length &&
            state.bidIndex < sortedBids.length
        ) {
            // Initialise the next iteration of the relevant variables
            state.nextOfferIndex = state.offerIndex;
            state.nextBidIndex = state.bidIndex;
            state.nextCumSumOffers = state.cumSumOffers;
            state.nextCumSumBids = state.cumSumBids;
            state.nextOfferPrice = sortedOffers[state.offerIndex]
                .offerPriceRevealed;

            // Obtain next offer index, increase cumulative sum
            while (
                state.nextOfferIndex < sortedOffers.length &&
                sortedOffers[state.nextOfferIndex].offerPriceRevealed ==
                state.nextOfferPrice
            )
                state.nextCumSumOffers += sortedOffers[state.nextOfferIndex++]
                    .amount;

            // Obtain next bid index, decrease cumulative sum
            (state.nextCumSumBids, state.nextBidIndex) = _decreaseCumSumBids(
                sortedBids,
                state.nextBidIndex,
                state.nextCumSumBids,
                state.nextOfferPrice
            );

            state.nextMaxClearingVolume = _minUint256(
                state.nextCumSumBids,
                state.nextCumSumOffers
            );
            if (state.nextMaxClearingVolume > state.maxClearingVolume) {
                state.offerIndex = state.nextOfferIndex;
                state.bidIndex = state.nextBidIndex;
                state.cumSumOffers = state.nextCumSumOffers;
                state.cumSumBids = state.nextCumSumBids;
                state.offerPrice = state.nextOfferPrice;
                state.maxClearingVolume = state.nextMaxClearingVolume;
            } else {
                break;
            }
        }

        // Get next offer price: first offer price higher than the pre-clearance price
        state.nextOfferPrice = (state.offerIndex < sortedOffers.length)
            ? sortedOffers[state.offerIndex].offerPriceRevealed
            : type(uint256).max;

        // Minimise css by minimising csb as long as bid price is smaller than next offer price
        while (state.bidIndex < sortedBids.length) {
            state.nextBidIndex = state.bidIndex;
            state.nextBidPrice = sortedBids[state.bidIndex].bidPriceRevealed;
            state.nextCumSumBids = state.cumSumBids;
            if (state.nextBidPrice < state.nextOfferPrice) {
                while (
                    state.nextBidIndex < sortedBids.length &&
                    sortedBids[state.nextBidIndex].bidPriceRevealed ==
                    state.nextBidPrice
                ) {
                    state.nextCumSumBids -= sortedBids[state.nextBidIndex++]
                        .amount;
                }
                if (state.nextCumSumBids >= state.cumSumOffers) {
                    state.minCumSumCorrection = true;
                    state.cumSumBids = state.nextCumSumBids;
                    state.bidIndex = state.nextBidIndex;
                } else {
                    break;
                }
            } else {
                break;
            }
        }

        // Calculate clearing price: bid price if minimum correction was made and offer price otherwise
        if (state.minCumSumCorrection)
            state.clearingPrice = (state.bidIndex == sortedBids.length)
                ? sortedBids[state.bidIndex - 1].bidPriceRevealed
                : sortedBids[state.bidIndex].bidPriceRevealed;
        else state.clearingPrice = state.offerPrice;

        // The main loop positions `offerIndex` at the first index greater than the price.
        // It needs to be shifted back to get the last index smaller than or equal to the price.
        state.offerIndex--;

        // If non-zero clearing offset, find the offset tender prices and then average them to find the final clearing price.
        if (clearingOffset == 1) {
            uint256 nextOfferPriceIndex = state.offerIndex;
            while (
                nextOfferPriceIndex > 0 &&
                sortedOffers[nextOfferPriceIndex].offerPriceRevealed ==
                sortedOffers[state.offerIndex].offerPriceRevealed
            ) {
                nextOfferPriceIndex -= 1;
            }

            uint256 nextBidPriceIndex = state.bidIndex;

            // In the case that there is no clear, bid index is past end of array, so decrement it to last element.
            if (state.bidIndex == sortedBids.length) {
                nextBidPriceIndex -= 1;
            }

            while (
                nextBidPriceIndex < sortedBids.length - 1 &&
                sortedBids[nextBidPriceIndex].bidPriceRevealed ==
                sortedBids[state.bidIndex].bidPriceRevealed
            ) {
                nextBidPriceIndex += 1;
            }

            state.clearingPrice =
                (sortedOffers[nextOfferPriceIndex].offerPriceRevealed +
                    sortedBids[nextBidPriceIndex].bidPriceRevealed) /
                2;
        } else {
            // In the case that there is no clear, bid index is past end of array, so decrement it to last element.
            if (state.bidIndex == sortedBids.length) {
                state.bidIndex -= 1;
            }
            state.clearingPrice =
                (sortedOffers[state.offerIndex].offerPriceRevealed +
                    sortedBids[state.bidIndex].bidPriceRevealed) /
                2;
        }

        //update state.cumSumOffers
        if (
            sortedOffers[state.offerIndex].offerPriceRevealed <=
            state.clearingPrice
        ) {
            state.offerIndex++;
            while (
                state.offerIndex < sortedOffers.length &&
                sortedOffers[state.offerIndex].offerPriceRevealed <=
                state.clearingPrice
            ) {
                state.cumSumOffers += sortedOffers[state.offerIndex].amount;
                state.offerIndex++;
            }
        } else {
            while (
                sortedOffers[state.offerIndex].offerPriceRevealed >
                state.clearingPrice
            ) {
                state.cumSumOffers -= sortedOffers[state.offerIndex].amount;
                if (state.offerIndex == 0) break;
                state.offerIndex--;
            }
        }

        //update state.cumSumBids
        if (
            state.bidIndex < sortedBids.length &&
            sortedBids[state.bidIndex].bidPriceRevealed < state.clearingPrice
        ) {
            (state.cumSumBids, state.bidIndex) = _decreaseCumSumBids(
                sortedBids,
                state.bidIndex,
                state.cumSumBids,
                state.clearingPrice
            );
        } else if (state.bidIndex > 0) {
            (state.cumSumBids, state.bidIndex) = _increaseCumSumBids(
                sortedBids,
                state.bidIndex - 1,
                state.cumSumBids,
                state.clearingPrice
            );
        }

        return (
            state.clearingPrice,
            _minUint256(state.cumSumBids, state.cumSumOffers)
        );
    }

    /// Finds the index of the first bid with a bidPrice of `price` and calculate the cumsum of the bid amounts up to that index
    /// @param price The price to search for
    /// @param sortedBids An array of sorted bids to search
    /// @param startIndex The index to start searching from
    /// @return i The index of the first bid with a bidPrice of `price`
    /// @return totalAmount The cumsum of the bid amounts up to return index i
    function _findFirstIndexForPrice(
        uint256 price,
        TermAuctionRevealedBid[] memory sortedBids,
        uint256 startIndex
    ) internal pure returns (uint256 i, uint256 totalAmount) {
        i = startIndex;
        totalAmount = sortedBids[i].amount;
        while (true) {
            if (i == 0 || sortedBids[i - 1].bidPriceRevealed != price) {
                break;
            }
            totalAmount += sortedBids[i - 1].amount;
            --i;
        }
        return (i, totalAmount);
    }

    /// Finds the index of the last offer with a offerPrice of `price` and calculate the cumsum of the offer amounts up to that index
    /// @param price The price to search for
    /// @param sortedOffers An array of offers to search
    /// @param startIndex The index to start searching from
    /// @return i The index of the last offer with a offerPrice of `price`
    /// @return totalAmount The cumsum of the offer amounts up to return index i
    function _findLastIndexForPrice(
        uint256 price,
        TermAuctionRevealedOffer[] memory sortedOffers,
        uint256 startIndex
    ) internal pure returns (uint256 i, uint256 totalAmount) {
        i = startIndex;
        totalAmount = sortedOffers[i].amount;
        while (i < (sortedOffers.length - 1)) {
            if (sortedOffers[i + 1].offerPriceRevealed != price) {
                break;
            }
            totalAmount += sortedOffers[i + 1].amount;
            ++i;
        }
        return (i, totalAmount);
    }

    /// Fully assigns a bid
    /// @param bid The bid to assign
    /// @return The amount that was assigned
    function _fullyAssignBid(
        TermAuctionRevealedBid memory bid
    ) internal nonReentrant returns (uint256) {
        uint256 repurchaseAmount = _calculateRepurchasePrice(bid.amount);

        if (!bid.isRollover) {
            termRepoServicer.fulfillBid(
                bid.bidder,
                bid.amount,
                repurchaseAmount,
                bid.collateralTokens,
                bid.collateralAmounts,
                dayCountFractionMantissa
            );
        } else {
            _assignRolloverBid(
                bid.bidder,
                bid.amount,
                repurchaseAmount,
                bid.rolloverPairOffTermRepoServicer
            );
        }

        emitter.emitBidAssigned(termAuctionId, bid.id, bid.amount);

        return bid.amount;
    }

    /// Fully assigns an offer
    /// @param offer The offer to assign
    /// @return The amount that was assigned
    function _fullyAssignOffer(
        TermAuctionRevealedOffer memory offer
    ) internal nonReentrant returns (uint256) {
        uint256 repurchaseAmount = _calculateRepurchasePrice(offer.amount);

        termRepoServicer.fulfillOffer(
            offer.offeror,
            offer.amount,
            repurchaseAmount,
            offer.id
        );

        emitter.emitOfferAssigned(termAuctionId, offer.id, offer.amount);

        return offer.amount;
    }

    /// Partially assigns a bid
    /// @param bid The bid to assign
    /// @param assignedAmount The amount to assign
    /// @return The amount that was assigned
    function _partiallyAssignBid(
        TermAuctionRevealedBid memory bid,
        uint256 assignedAmount
    ) internal nonReentrant returns (uint256) {
        uint256 repurchaseAmount = _calculateRepurchasePrice(assignedAmount);

        if (!bid.isRollover) {
            termRepoServicer.fulfillBid(
                bid.bidder,
                assignedAmount,
                repurchaseAmount,
                bid.collateralTokens,
                bid.collateralAmounts,
                dayCountFractionMantissa
            );
        } else {
            _assignRolloverBid(
                bid.bidder,
                assignedAmount,
                repurchaseAmount,
                bid.rolloverPairOffTermRepoServicer
            );
        }

        emitter.emitBidAssigned(termAuctionId, bid.id, assignedAmount);

        return assignedAmount;
    }

    /// Partially assigns an offer
    /// @param offer The offer to assign
    /// @param assignedAmount The amount to assign
    /// @return The amount that was assigned
    function _partiallyAssignOffer(
        TermAuctionRevealedOffer memory offer,
        uint256 assignedAmount
    ) internal nonReentrant returns (uint256) {
        uint256 repurchaseAmount = _calculateRepurchasePrice(assignedAmount);

        termRepoServicer.fulfillOffer(
            offer.offeror,
            assignedAmount,
            repurchaseAmount,
            offer.id
        );

        // Unlock remaining.
        termAuctionOfferLocker.unlockOfferPartial(
            offer.id,
            offer.offeror,
            offer.amount - assignedAmount
        );

        emitter.emitOfferAssigned(termAuctionId, offer.id, assignedAmount);

        return assignedAmount;
    }

    function _assignRolloverBid(
        address borrower,
        uint256 purchasePrice,
        uint256 repurchasePrice,
        address rolloverPairOffTermRepoServicer
    ) internal {
        ITermRepoServicer previousTermRepoServicer = ITermRepoServicer(
            rolloverPairOffTermRepoServicer
        );
        uint256 rolloverPaymentToCollapseBorrower = termRepoServicer
            .openExposureOnRolloverNew(
                borrower,
                purchasePrice,
                repurchasePrice,
                address(previousTermRepoServicer.termRepoLocker()),
                dayCountFractionMantissa
            );
        uint256 proportionPreviousLoanPaid = previousTermRepoServicer
            .closeExposureOnRolloverExisting(
                borrower,
                rolloverPaymentToCollapseBorrower
            );
        ITermRepoCollateralManager previousTermRepoCollateralManager = ITermRepoCollateralManager(
                previousTermRepoServicer.termRepoCollateralManager()
            );
        (
            address[] memory collateralTypes,
            uint256[] memory collateralAmounts
        ) = previousTermRepoCollateralManager.transferRolloverCollateral(
                borrower,
                proportionPreviousLoanPaid,
                address(termRepoServicer.termRepoLocker())
            );

        ITermRepoCollateralManager currentTermRepoCollateralManager = termRepoServicer
                .termRepoCollateralManager();

        for (uint256 i = 0; i < collateralTypes.length; ++i) {
            if (collateralAmounts[i] > 0) {
                currentTermRepoCollateralManager.acceptRolloverCollateral(
                    borrower,
                    collateralTypes[i],
                    collateralAmounts[i]
                );
            }
        }
    }

    function _markRolloverAsProcessed(
        address rolloverPairOffTermRepoServicer,
        address borrower
    ) internal {
        ITermRepoServicer termRepoServicer_ = ITermRepoServicer(
            rolloverPairOffTermRepoServicer
        );
        ITermRepoRolloverManager rolloverManager = termRepoServicer_
            .termRepoRolloverManager();
        rolloverManager.fulfillRollover(borrower);
    }

    /// Assigns bids up to `maxAssignable`
    /// @dev This method allocates pro-rata across an the marginal price group (pro-rata on the margin) and attempts to prevent residuals from accumulating to a single bid
    /// @param sortedBids An array of sorted bids to process
    /// @param maxAssignable The maximum bid amount that can be assigned across all bidders
    /// @param purchaseTokenDecimals The number of decimals of the purchase token
    /// @return The total amount assigned
    function _assignBids(
        TermAuctionRevealedBid[] memory sortedBids,
        uint256 maxAssignable,
        uint256 purchaseTokenDecimals
    ) internal returns (uint256) {
        // Process revealed bids.
        uint256 totalAssignedBids = 0;
        uint256 innerIndex = 0;
        uint256 i = 0;
        for (uint256 j = sortedBids.length; j > 0; --j) {
            i = j - 1;

            // First, find the sub-range that contains the current price.
            (uint256 k, uint256 priceGroupAmount) = _findFirstIndexForPrice(
                sortedBids[i].bidPriceRevealed,
                sortedBids,
                i
            );
            // NOTE: priceGroupAmount gets changed later on in this function and is used as the "remaining" priceGroupAmount during partial assignment.

            if (
                sortedBids[i].bidPriceRevealed >= clearingPrice &&
                totalAssignedBids < maxAssignable &&
                priceGroupAmount <= (maxAssignable - totalAssignedBids)
            ) {
                // Full assignment for entire price group.

                innerIndex = 0;
                for (; (i - innerIndex) >= k; ++innerIndex) {
                    // NOTE: This loop is actually decrementing!
                    totalAssignedBids += _fullyAssignBid(
                        sortedBids[i - innerIndex]
                    );

                    if (i == innerIndex) {
                        ++innerIndex;
                        break;
                    }
                }
                if (innerIndex > 0) {
                    j -= (innerIndex - 1);
                }
            } else if (
                sortedBids[i].bidPriceRevealed >= clearingPrice &&
                totalAssignedBids < maxAssignable
            ) {
                // Partial assignment for entire price group.

                innerIndex = 0;
                for (; (i - innerIndex) >= k; ++innerIndex) {
                    if ((i - innerIndex) == k) {
                        // Last iteration of loop. Assign remaining amount left to assign.
                        totalAssignedBids += _partiallyAssignBid(
                            sortedBids[i - innerIndex],
                            maxAssignable - totalAssignedBids
                        );
                        priceGroupAmount -= maxAssignable - totalAssignedBids;
                    } else {
                        // Assign an amount based upon the partial assignment ratio.

                        uint256 bidAmount = sortedBids[i - innerIndex].amount;
                        Exp memory partialAssignmentRatio = div_(
                            Exp({
                                mantissa: (maxAssignable - totalAssignedBids) *
                                    10 ** (18 - purchaseTokenDecimals)
                            }),
                            Exp({
                                mantissa: priceGroupAmount *
                                    10 ** (18 - purchaseTokenDecimals)
                            })
                        );
                        uint256 assignedAmount = mul_(
                            partialAssignmentRatio,
                            Exp({
                                mantissa: bidAmount *
                                    10 ** (18 - purchaseTokenDecimals)
                            })
                        ).mantissa / 10 ** (18 - purchaseTokenDecimals);

                        totalAssignedBids += _partiallyAssignBid(
                            sortedBids[i - innerIndex],
                            assignedAmount
                        );
                        priceGroupAmount -= sortedBids[i - innerIndex].amount;
                    }

                    if (i == innerIndex) {
                        ++innerIndex;
                        break;
                    }
                }
                if (innerIndex > 0) {
                    j -= (innerIndex - 1);
                }
            } else {
                // No assignment.
                if (sortedBids[i].isRollover) {
                    _markRolloverAsProcessed(
                        sortedBids[i].rolloverPairOffTermRepoServicer,
                        sortedBids[i].bidder
                    );
                } else {
                    termAuctionBidLocker.auctionUnlockBid(
                        sortedBids[i].id,
                        sortedBids[i].bidder,
                        sortedBids[i].collateralTokens,
                        sortedBids[i].collateralAmounts
                    );
                }
            }
        }

        return totalAssignedBids;
    }

    /// Assigns offers up to `maxAssignable`
    /// @dev This method allocates pro-rata across an the marginal price group (pro-rata on the margin) and attempts to prevent residuals from accumulating to a single offer
    /// @param sortedOffers An array of sorted offers to process
    /// @param maxAssignable The maximum offer amount that can be assigned across all offers
    /// @param purchaseTokenDecimals The number of decimals of the purchase token
    /// @return The total amount assigned
    function _assignOffers(
        TermAuctionRevealedOffer[] memory sortedOffers,
        uint256 maxAssignable,
        uint256 purchaseTokenDecimals
    ) internal returns (uint256) {
        // Process revealed offers.
        uint256 totalAssignedOffers = 0;
        uint256 innerIndex = 0;
        uint256 i = 0;
        for (i = 0; i < sortedOffers.length; ++i) {
            // First, find the sub-range that contains the current price.
            (uint256 k, uint256 priceGroupAmount) = _findLastIndexForPrice(
                sortedOffers[i].offerPriceRevealed,
                sortedOffers,
                i
            );
            // NOTE: priceGroupAmount gets changed later on in this function and is used as the "remaining" priceGroupAmount during partial assignment.

            if (
                sortedOffers[i].offerPriceRevealed <= clearingPrice &&
                totalAssignedOffers < maxAssignable &&
                priceGroupAmount <= (maxAssignable - totalAssignedOffers)
            ) {
                // Full assignment.
                innerIndex = 0;
                for (; (innerIndex + i) <= k; ++innerIndex) {
                    totalAssignedOffers += _fullyAssignOffer(
                        sortedOffers[innerIndex + i]
                    );
                }
                if (innerIndex > 0) {
                    i += innerIndex - 1;
                }
            } else if (
                sortedOffers[i].offerPriceRevealed <= clearingPrice &&
                totalAssignedOffers < maxAssignable
            ) {
                // Partial assignment.
                innerIndex = 0;
                for (; (innerIndex + i) <= k; innerIndex++) {
                    if ((innerIndex + i) == k) {
                        // Last iteration of loop. Assign remaining amount left to assign.
                        totalAssignedOffers += _partiallyAssignOffer(
                            sortedOffers[innerIndex + i],
                            maxAssignable - totalAssignedOffers
                        );
                        priceGroupAmount -= maxAssignable - totalAssignedOffers;
                    } else {
                        // Assign an amount based upon the partial assignment ratio.

                        uint256 offerAmount = sortedOffers[innerIndex + i]
                            .amount;
                        Exp memory partialAssignmentRatio = div_(
                            Exp({
                                mantissa: (maxAssignable -
                                    totalAssignedOffers) *
                                    10 ** (18 - purchaseTokenDecimals)
                            }),
                            Exp({
                                mantissa: priceGroupAmount *
                                    10 ** (18 - purchaseTokenDecimals)
                            })
                        );
                        uint256 assignedAmount = (innerIndex + i) != k
                            ? mul_(
                                partialAssignmentRatio,
                                Exp({
                                    mantissa: offerAmount *
                                        10 ** (18 - purchaseTokenDecimals)
                                })
                            ).mantissa / 10 ** (18 - purchaseTokenDecimals)
                            : maxAssignable - totalAssignedOffers;

                        totalAssignedOffers += _partiallyAssignOffer(
                            sortedOffers[innerIndex + i],
                            assignedAmount
                        );
                        priceGroupAmount -= sortedOffers[innerIndex + i].amount;
                    }
                }
                if (innerIndex > 0) {
                    i += innerIndex - 1;
                }
            } else {
                // No assignment.

                // Return purchase tokens to offeror.
                termAuctionOfferLocker.unlockOfferPartial(
                    sortedOffers[i].id,
                    sortedOffers[i].offeror,
                    sortedOffers[i].amount
                );
            }
        }

        return totalAssignedOffers;
    }

    /// Calculates repurchase price given a purchase price (equivalent to principal plus interest)
    /// @param purchasePrice The purchase price
    /// @return The repurchase price obtained by applying the clearing rate on an Actual/360 day-count convention
    function _calculateRepurchasePrice(
        uint256 purchasePrice
    ) internal view returns (uint256) {
        Exp memory repurchaseFactor = add_(
            Exp({mantissa: expScale}),
            mul_(
                Exp({mantissa: dayCountFractionMantissa}),
                Exp({mantissa: clearingPrice})
            )
        );

        return
            truncate(
                mul_(
                    Exp({mantissa: purchasePrice * expScale}),
                    repurchaseFactor
                )
            );
    }

    function _calculateAndStoreClearingPrice(
        TermAuctionRevealedBid[] memory sortedBids,
        TermAuctionRevealedOffer[] memory sortedOffers
    ) internal nonReentrant returns (uint256, uint256) {
        (
            uint256 clearingPrice_,
            uint256 maxAssignable
        ) = _calculateClearingPrice(
                sortedBids,
                sortedOffers,
                CLEARING_PRICE_POST_PROCESSING_OFFSET
            );

        clearingPrice = clearingPrice_;

        return (clearingPrice_, maxAssignable);
    }

    // ========================================================================
    // = Pausable =============================================================
    // ========================================================================

    /// @dev This function pauses the TermAuction contract preventing public state changes
    /// @dev See {Pausable-_pause}.
    function pauseCompleteAuction() external onlyRole(DEFAULT_ADMIN_ROLE) {
        completeAuctionPaused = true;
        emitter.emitCompleteAuctionPaused(termAuctionId, termRepoId);
    }

    /// Unpuses the TermAuction contract allowing public state changes
    /// @dev See {Pausable-_unpause}.
    function unpauseCompleteAuction() external onlyRole(DEFAULT_ADMIN_ROLE) {
        completeAuctionPaused = false;
        emitter.emitCompleteAuctionUnpaused(termAuctionId, termRepoId);
    }

    // solhint-disable no-empty-blocks
    ///@dev required override by the OpenZeppelin UUPS module
    function _authorizeUpgrade(
        address
    ) internal view override onlyRole(DEFAULT_ADMIN_ROLE) {}
    // solhint-enable no-empty-blocks
}