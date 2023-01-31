// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

/// @dev Taken from https://github.com/f8n/fnd-protocol/tree/v2.0.3

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "./NFTMarketAuction.sol";
import "./NFTMarketCore.sol";
import "./SendValueWithFallbackWithdraw.sol";

// The gas limit to send ETH to a single recipient, enough for a contract with a simple receiver.
uint256 constant SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT = 20000;

// solhint-disable max-line-length
string constant ReserveAuction_Already_Listed = "ReserveAuction_Already_Listed";
string constant ReserveAuction_Bid_Must_Be_At_Least_Min_Amount = "ReserveAuction_Bid_Must_Be_At_Least_Min_Amount";
string constant ReserveAuction_Cannot_Admin_Cancel_Without_Reason = "ReserveAuction_Cannot_Admin_Cancel_Without_Reason";
string constant ReserveAuction_Cannot_Bid_Lower_Than_Reserve_Price = "ReserveAuction_Cannot_Bid_Lower_Than_Reserve_Price";
string constant ReserveAuction_Cannot_Bid_On_Ended_Auction = "ReserveAuction_Cannot_Bid_On_Ended_Auction";
string constant ReserveAuction_Cannot_Bid_On_Nonexistent_Auction = "ReserveAuction_Cannot_Bid_On_Nonexistent_Auction";
string constant ReserveAuction_Cannot_Cancel_Nonexistent_Auction = "ReserveAuction_Cannot_Cancel_Nonexistent_Auction";
string constant ReserveAuction_Cannot_Finalize_Already_Settled_Auction = "ReserveAuction_Cannot_Finalize_Already_Settled_Auction";
string constant ReserveAuction_Cannot_Finalize_Auction_In_Progress = "ReserveAuction_Cannot_Finalize_Auction_In_Progress";
string constant ReserveAuction_Cannot_Rebid_Over_Outstanding_Bid = "ReserveAuction_Cannot_Rebid_Over_Outstanding_Bid";
string constant ReserveAuction_Cannot_Update_Auction_In_Progress = "ReserveAuction_Cannot_Update_Auction_In_Progress";
string constant ReserveAuction_Subceeds_Min_Duration = "ReserveAuction_Subceeds_Min_Duration";
string constant ReserveAuction_Exceeds_Max_Duration = "ReserveAuction_Exceeds_Max_Duration";
string constant ReserveAuction_Less_Than_Extension_Duration = "ReserveAuction_Less_Than_Extension_Duration";
string constant ReserveAuction_Must_Set_Non_Zero_Reserve_Price = "ReserveAuction_Must_Set_Non_Zero_Reserve_Price";
string constant ReserveAuction_Not_Matching_Bidder = "ReserveAuction_Not_Matching_Bidder";
string constant ReserveAuction_Only_Owner_Can_Update_Auction = "ReserveAuction_Only_Owner_Can_Update_Auction";
string constant ReserveAuction_Price_Already_Set = "ReserveAuction_Price_Already_Set";

// solhint-enable max-line-length

/**
 * @title Allows the owner of an NFT to list it in auction.
 * @notice NFTs in auction are escrowed in the market contract.
 */
abstract contract NFTMarketReserveAuction is
    ReentrancyGuardUpgradeable,
    NFTMarketCore,
    NFTMarketAuction,
    SendValueWithFallbackWithdraw
{
    // Stores the auction configuration for a specific NFT.
    struct ReserveAuction {
        // The address of the NFT contract.
        address nftContract;
        // The id of the NFT.
        uint256 tokenId;
        // The owner of the NFT which listed it in auction.
        address payable seller;
        // The duration for this auction.
        uint256 duration;
        // The extension window for this auction.
        uint256 extensionDuration;
        // The time at which this auction will not accept any new bids.
        // @dev This is `0` until the first bid is placed.
        uint256 endTime;
        // The current highest bidder in this auction.
        // @dev This is `address(0)` until the first bid is placed.
        address payable bidder;
        // The latest amount locked in for this auction. Includes buyerFee.
        // @dev This is set to the reserve price + buyerFee, and then to the highest bid once the auction has started.
        uint256 amount;
        // The buyerFee at the moment the auction was created. Expressed as x1000 (ej: 100 => 10% = 0.1)
        uint8 buyerFeePermille;
        // The sellerFee at the moment the auction was created. Expressed as x1000 (ej: 100 => 10% = 0.1)
        uint8 sellerFeePermille;
    }

    /// @dev The auction configuration for a specific auction id.
    mapping(address => mapping(uint256 => uint256)) internal nftContractToTokenIdToAuctionId;

    /// @dev The auction id for a specific NFT.
    /// @dev This is deleted when an auction is finalized or canceled.
    mapping(uint256 => ReserveAuction) internal auctionIdToAuction;

    /// @dev Minimal value for how long an auction can lasts for once the first bid has been received.
    uint256 internal minDuration;

    /// @dev Maximal value for how long an auction can lasts for once the first bid has been received.
    uint256 internal maxDuration;

    /// @dev The window for auction extensions, any bid placed in the final 15 minutes
    /// of an auction will reset the time remaining to 15 minutes.
    uint256 internal constant EXTENSION_DURATION = 15 minutes;

    /// @dev Caps the max duration that may be configured so that overflows will not occur.
    uint256 internal constant MAX_MAX_DURATION = 1000 days;

    /**
     * @notice Emitted when a bid is placed.
     * @param auctionId The id of the auction this bid was for.
     * @param bidder The address of the bidder.
     * @param amount The amount of the bid.
     * @param endTime The new end time of the auction (which may have been set or extended by this bid).
     */
    event ReserveAuctionBidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount, uint256 endTime);
    /**
     * @notice Emitted when an auction is cancelled.
     * @dev This is only possible if the auction has not received any bids.
     * @param auctionId The id of the auction that was cancelled.
     */
    event ReserveAuctionCanceled(uint256 indexed auctionId);
    /**
     * @notice Emitted when an auction is canceled by a Enigma admin.
     * @dev When this occurs, the highest bidder (if there was a bid) is automatically refunded.
     * @param auctionId The id of the auction that was cancelled.
     * @param reason The reason for the cancellation.
     */
    event ReserveAuctionCanceledByAdmin(uint256 indexed auctionId, string reason);
    /**
     * @notice Emitted when an NFT is listed for auction.
     * @param seller The address of the seller.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The id of the NFT.
     * @param duration The duration of the auction (always 24-hours).
     * @param extensionDuration The duration of the auction extension window (always 15-minutes).
     * @param reservePrice The reserve price to kick off the auction.
     * @param bidAmount Reserve price, plus buyerFee. Min amount required to win this auction.
     * @param auctionId The id of the auction that was created.
     */
    event ReserveAuctionCreated(
        address indexed seller,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 duration,
        uint256 extensionDuration,
        uint256 reservePrice,
        uint256 bidAmount,
        uint256 auctionId
    );
    /**
     * @notice Emitted when an auction that has already ended is finalized,
     * indicating that the NFT has been transferred and revenue from the sale distributed.
     * @dev The amount of the highest bid / final sale price for this auction is `f8nFee` + `creatorFee` + `ownerRev`.
     * @param auctionId The id of the auction that was finalized.
     * @param seller The address of the seller.
     * @param bidder The address of the highest bidder that won the NFT.
     * @param platformFee The amount of ETH that was sent to Enigma for this sale.
     * @param royaltyFee The amount of ETH that was sent to the creator for this sale.
     * @param sellerRev The amount of ETH that was sent to the sellet for this NFT.
     */
    event ReserveAuctionFinalized(
        uint256 indexed auctionId,
        address indexed seller,
        address indexed bidder,
        uint256 platformFee,
        uint256 royaltyFee,
        uint256 sellerRev
    );
    /**
     * @notice Emitted when the auction's reserve price is changed.
     * @dev This is only possible if the auction has not received any bids.
     * @param auctionId The id of the auction that was updated.
     * @param reservePrice The new reserve price for the auction.
     */
    event ReserveAuctionUpdated(uint256 indexed auctionId, uint256 reservePrice);

    /// @notice Confirms that the reserve price is not zero.
    modifier onlyValidAuctionConfig(uint256 reservePrice) {
        if (reservePrice == 0) {
            revert(ReserveAuction_Must_Set_Non_Zero_Reserve_Price);
        }
        _;
    }

    /// oz-upgrades-unsafe-allow constructor
    // solhint-disable-next-line
    constructor() {}

    /**
     * @notice Configures the duration for auctions.
     * @param _minDuration The min duration for auctions, in seconds.
     * @param _maxDuration The max duration for auctions, in seconds.
     */
    function _initializeNFTMarketReserveAuction(uint256 _minDuration, uint256 _maxDuration) internal {
        if (_maxDuration > MAX_MAX_DURATION) {
            // This ensures that math in this file will not overflow due to a huge duration.
            revert(ReserveAuction_Exceeds_Max_Duration);
        }
        if (_minDuration < EXTENSION_DURATION) {
            // The auction duration configuration must be greater than the extension window of 15 minutes
            revert(ReserveAuction_Less_Than_Extension_Duration);
        }
        minDuration = _minDuration;
        maxDuration = _maxDuration;
    }

    /**
     * @notice Creates an auction for the given NFT.
     * The NFT is held in escrow until the auction is finalized or canceled.
     * buyer and seller fees are locked at creation time
     * @dev IMPORTANT! The platform fees are assumed to be authenticated, otherwise this may cause security issues
     * @param nftContract The address of the NFT contract.
     * @param tokenId The id of the NFT.
     * @param duration seconds for how long an auction lasts for once the first bid has been received.
     * @param reservePrice The initial reserve price for the auction.
     */
    function createReserveAuctionFor(
        address nftContract,
        uint256 tokenId,
        uint256 duration,
        uint256 reservePrice,
        uint256 amount,
        PlatformFees calldata platformFees
    ) internal virtual {
        uint256 auctionId = nftContractToTokenIdToAuctionId[nftContract][tokenId];
        if (auctionId == 0) {
            // NFT is not in auction
            // If the `msg.sender` is not the owner of the NFT, transferring into escrow should fail.
            _transferToEscrow(nftContract, tokenId);
        } else {
            // Using storage saves gas since most of the data is not needed
            ReserveAuction storage auction = auctionIdToAuction[auctionId];
            if (auction.endTime == 0) {
                revert(ReserveAuction_Already_Listed);
            } else {
                // Auction in progress, confirm the highest bidder is a match
                if (auction.bidder != msg.sender) {
                    revert(ReserveAuction_Not_Matching_Bidder);
                }

                // Finalize auction but leave NFT in escrow, reverts if the auction has not ended
                _finalizeReserveAuction({ auctionId: auctionId, keepInEscrow: true });
            }
        }
        // Get the new Id
        auctionId = _getNextAndIncrementAuctionId();

        // This checks if duration is between acceptable
        if (minDuration > duration) {
            revert(ReserveAuction_Subceeds_Min_Duration);
        }
        if (duration > maxDuration) {
            revert(ReserveAuction_Exceeds_Max_Duration);
        }

        // Store the auction details
        nftContractToTokenIdToAuctionId[nftContract][tokenId] = auctionId;
        auctionIdToAuction[auctionId] = ReserveAuction(
            nftContract,
            tokenId,
            payable(msg.sender),
            duration,
            EXTENSION_DURATION,
            0, // endTime is only known once the reserve price is met
            payable(0), // bidder is only known once a bid has been placed
            amount,
            platformFees.buyerFeePermille, // fees are locked-in at create time
            platformFees.sellerFeePermille
        );

        emit ReserveAuctionCreated(
            msg.sender,
            nftContract,
            tokenId,
            duration,
            EXTENSION_DURATION,
            reservePrice,
            amount,
            auctionId
        );
    }

    /**
     * @notice Once the countdown has expired for an auction, anyone can settle the auction.
     * This will send the NFT to the highest bidder and distribute revenue for this sale.
     * @param auctionId The id of the auction to settle.
     */
    function finalizeReserveAuction(uint256 auctionId) external nonReentrant {
        if (auctionIdToAuction[auctionId].endTime == 0) {
            revert(ReserveAuction_Cannot_Finalize_Already_Settled_Auction);
        }
        _finalizeReserveAuction({ auctionId: auctionId, keepInEscrow: false });
    }

    /**
     * @notice Settle an auction that has already ended.
     * This will send the NFT to the highest bidder and distribute revenue for this sale.
     * @param keepInEscrow If true, the NFT will be kept in escrow to save gas by avoiding
     * redundant transfers if the NFT should remain in escrow, such as when the new owner
     * sets a buy price or lists it in a new auction.
     */
    function _finalizeReserveAuction(uint256 auctionId, bool keepInEscrow) internal {
        ReserveAuction memory auction = auctionIdToAuction[auctionId];

        if (auction.endTime >= block.timestamp) {
            revert(ReserveAuction_Cannot_Finalize_Auction_In_Progress);
        }

        // Remove the auction.
        delete nftContractToTokenIdToAuctionId[auction.nftContract][auction.tokenId];
        delete auctionIdToAuction[auctionId];

        if (!keepInEscrow) {
            // The seller was authorized when the auction was originally created
            _transferFromEscrow(auction.nftContract, auction.tokenId, auction.bidder);
        }

        // Distribute revenue for this sale.
        (uint256 platformFee, uint256 royaltyFee, uint256 assetFee) = _distAuctionFunds(auction);

        emit ReserveAuctionFinalized(auctionId, auction.seller, auction.bidder, platformFee, royaltyFee, assetFee);
    }

    function _distAuctionFunds(ReserveAuction memory auction)
        internal
        returns (
            uint256 platformFee,
            uint256 royaltyFee,
            uint256 assetFee
        )
    {
        return
            _distFunds(
                auction.nftContract,
                auction.tokenId,
                auction.amount,
                auction.seller,
                auction.sellerFeePermille,
                auction.buyerFeePermille
            );
    }

    /**
     * @notice Allows Enigma to cancel an auction, refunding the bidder and returning the NFT to
     * the seller (if not active buy price set).
     * This should only be used for extreme cases such as DMCA takedown requests.
     * @param auctionId The id of the auction to cancel.
     * @param reason The reason for the cancellation (a required field).
     */
    function adminCancelReserveAuction(uint256 auctionId, string calldata reason) external onlyOwner nonReentrant {
        if (bytes(reason).length == 0) {
            revert(ReserveAuction_Cannot_Admin_Cancel_Without_Reason);
        }
        ReserveAuction memory auction = auctionIdToAuction[auctionId];
        if (auction.amount == 0) {
            revert(ReserveAuction_Cannot_Cancel_Nonexistent_Auction);
        }

        delete nftContractToTokenIdToAuctionId[auction.nftContract][auction.tokenId];
        delete auctionIdToAuction[auctionId];

        // Return the NFT to the owner.
        _transferFromEscrow(auction.nftContract, auction.tokenId, auction.seller);

        if (auction.bidder != address(0)) {
            // Refund the highest bidder if any bids were placed in this auction.
            _sendValueWithFallbackWithdraw(auction.bidder, auction.amount, SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);
        }

        emit ReserveAuctionCanceledByAdmin(auctionId, reason);
    }

    /**
     * @notice If an auction has been created but has not yet received bids, it may be canceled by the seller.
     * @dev The NFT is transferred back to the owner unless there is still a buy price set.
     * @param auctionId The id of the auction to cancel.
     */
    function cancelReserveAuction(uint256 auctionId) external nonReentrant {
        ReserveAuction memory auction = auctionIdToAuction[auctionId];
        if (auction.amount == 0) {
            revert(ReserveAuction_Cannot_Cancel_Nonexistent_Auction);
        }
        if (auction.seller != msg.sender) {
            revert(ReserveAuction_Only_Owner_Can_Update_Auction);
        }
        if (auction.endTime != 0) {
            revert(ReserveAuction_Cannot_Update_Auction_In_Progress);
        }

        // Remove the auction.
        delete nftContractToTokenIdToAuctionId[auction.nftContract][auction.tokenId];
        delete auctionIdToAuction[auctionId];

        // Transfer the NFT.
        _transferFromEscrow(auction.nftContract, auction.tokenId, auction.seller);

        emit ReserveAuctionCanceled(auctionId);
    }

    /**
     * @notice Place a bid in an auction.
     * A bidder may place a bid which is at least the value defined by `getMinBidAmount`.
     * If this is the first bid on the auction, the countdown will begin.
     * If there is already an outstanding bid, the previous bidder will be refunded at this time
     * and if the bid is placed in the final moments of the auction, the countdown may be extended.
     * @param auctionId The id of the auction to bid on.
     */
    /* solhint-disable-next-line code-complexity */
    function placeBid(uint256 auctionId) external payable nonReentrant {
        ReserveAuction storage auction = auctionIdToAuction[auctionId];

        if (auction.amount == 0) {
            // No auction found
            revert(ReserveAuction_Cannot_Bid_On_Nonexistent_Auction);
        }

        uint256 endTime = auction.endTime;
        if (endTime == 0) {
            // This is the first bid, kicking off the auction.

            if (msg.value < auction.amount) {
                // The bid must be >= the reserve price.
                revert(ReserveAuction_Cannot_Bid_Lower_Than_Reserve_Price);
            }

            // Store the bid details.
            auction.amount = msg.value;
            auction.bidder = payable(msg.sender);

            // On the first bid, set the endTime to now + duration.
            // Duration is always less than MAX MAX, so the below can't overflow.
            endTime = block.timestamp + auction.duration;

            auction.endTime = endTime;
        } else {
            if (endTime < block.timestamp) {
                // The auction has already ended.
                revert(ReserveAuction_Cannot_Bid_On_Ended_Auction);
            } else if (auction.bidder == msg.sender) {
                // We currently do not allow a bidder to increase their bid unless another user has outbid them first.
                revert(ReserveAuction_Cannot_Rebid_Over_Outstanding_Bid);
            } else {
                uint256 minIncrement = _getMinIncrement(auction.amount);
                if (msg.value < minIncrement) {
                    // If this bid outbids another, it must be at least 10% greater than the last bid.
                    revert(ReserveAuction_Bid_Must_Be_At_Least_Min_Amount);
                }
            }

            // Cache and update bidder state
            uint256 originalAmount = auction.amount;
            address payable originalBidder = auction.bidder;
            auction.amount = msg.value;
            auction.bidder = payable(msg.sender);

            // When a bid outbids another, check to see if a time extension should apply.
            // We confirmed that the auction has not ended, so endTime is always >= the current timestamp.
            // Current time plus extension duration (always 15 mins) cannot overflow.
            uint256 endTimeWithExtension = block.timestamp + EXTENSION_DURATION;
            if (endTime < endTimeWithExtension) {
                endTime = endTimeWithExtension;
                auction.endTime = endTime;
            }
            // Refund the previous bidder
            _sendValueWithFallbackWithdraw(originalBidder, originalAmount, SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);
        }
        emit ReserveAuctionBidPlaced(auctionId, msg.sender, msg.value, endTime);
    }

    /**
     * @notice If an auction has been created but has not yet received bids, the reservePrice may be
     * changed by the seller.
     * @param auctionId The id of the auction to change.
     * @param reservePrice The new reserve price for this auction.
     */
    function updateReserveAuction(uint256 auctionId, uint256 reservePrice)
        external
        onlyValidAuctionConfig(reservePrice)
    {
        ReserveAuction storage auction = auctionIdToAuction[auctionId];
        if (auction.seller != msg.sender) {
            revert(ReserveAuction_Only_Owner_Can_Update_Auction);
        } else if (auction.endTime != 0) {
            revert(ReserveAuction_Cannot_Update_Auction_In_Progress);
        }

        // get the amount, including buyer fee for this reserve price
        uint256 amount = applyBuyerFee(reservePrice, auction.buyerFeePermille);
        if (auction.amount == amount) revert(ReserveAuction_Price_Already_Set);

        // Update the current reserve price.
        auction.amount = amount;

        emit ReserveAuctionUpdated(auctionId, reservePrice);
    }

    /**
     * @notice Returns the minimum amount a bidder must spend to participate in an auction.
     * Bids must be greater than or equal to this value or they will revert.
     * @param auctionId The id of the auction to check.
     * @return minimum The minimum amount for a bid to be accepted.
     */
    function getMinBidAmount(uint256 auctionId) external view returns (uint256 minimum) {
        ReserveAuction storage auction = auctionIdToAuction[auctionId];
        if (auction.endTime == 0) {
            return auction.amount;
        }
        return _getMinIncrement(auction.amount);
    }

    /**
     * @notice Returns auction details for a given auctionId.
     * @param auctionId The id of the auction to lookup.
     * @return auction The auction details.
     */
    function getReserveAuction(uint256 auctionId) external view returns (ReserveAuction memory auction) {
        return auctionIdToAuction[auctionId];
    }

    /**
     * @notice Returns the auctionId for a given NFT, or 0 if no auction is found.
     * @dev If an auction is canceled, it will not be returned. However the auction may be over
     *  and pending finalization.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The id of the NFT.
     * @return auctionId The id of the auction, or 0 if no auction is found.
     */
    function getReserveAuctionIdFor(address nftContract, uint256 tokenId) external view returns (uint256 auctionId) {
        auctionId = nftContractToTokenIdToAuctionId[nftContract][tokenId];
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[1000] private __gap;
}