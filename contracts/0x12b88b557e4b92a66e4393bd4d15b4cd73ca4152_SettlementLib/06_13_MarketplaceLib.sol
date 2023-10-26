// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: VERTICAL.art

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "@manifoldxyz/libraries-solidity/contracts/access/IAdminControl.sol";

import "../ILazyDelivery.sol";

import "./TokenLib.sol";

/**
 * Interface for Ownable contracts
 */
interface IOwnable {
    function owner() external view returns (address);
}

/**
 * @dev Marketplace libraries
 */
library MarketplaceLib {
    using AddressUpgradeable for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Events
    event CreateListing(
        uint40 indexed listingId,
        uint16 marketplaceBPS,
        uint8 listingType,
        uint24 totalAvailable,
        uint24 editionSize,
        uint48 startTime,
        uint48 endTime,
        uint256 initialAmount,
        uint16 extensionInterval,
        uint16 minIncrementBPS,
        address erc20
    );
    event CreateListingTokenDetails(
        uint40 indexed listingId,
        uint256 id,
        address address_,
        uint8 spec,
        bool lazy
    );
    event CreateListingFees(
        uint40 indexed listingId,
        uint16 deliverBPS,
        uint240 deliverFixed
    );

    event PurchaseEvent(
        uint40 indexed listingId,
        address buyer,
        uint24 count,
        uint256 amount
    );
    event BidEvent(uint40 indexed listingId, address bidder, uint256 amount);
    event OfferEvent(uint40 indexed listingId, address oferrer, uint256 amount);
    event RescindOfferEvent(
        uint40 indexed listingId,
        address oferrer,
        uint256 amount
    );
    event AcceptOfferEvent(
        uint40 indexed listingId,
        address oferrer,
        uint256 amount
    );
    event ModifyListing(
        uint40 indexed listingId,
        uint256 initialAmount,
        uint48 startTime,
        uint48 endTime
    );
    event CancelListing(
        uint40 indexed listingId,
        address requestor,
        uint16 holdbackBPS
    );
    event FinalizeListing(uint40 indexed listingId);

    // Listing types
    enum ListingType {
        INVALID,
        FIXED_PRICE,
        OFFERS_ONLY,
        INDIVIDUAL_AUCTION,
        RANKED_AUCTION,
        LINEAR_DUTCH_AUCTION,
        EXPO_DUTCH_AUCTION,
        SETTLEMENT_DUTCH_AUCTION
    }

    /**
     * @dev Listing structure
     *
     * @param seller          - the selling party
     * @param flags           - bit flag (hasBid, finalized, tokenCreator).  See FLAG_MASK_*
     * @param totalSold       - total number of items sold.
     * @param marketplaceBPS  - Marketplace fee BPS
     * @param curationBPS     - curation fee BPS
     * @param bidCount        - bid count
     * @param details         - ListingDetails.  Contains listing configuration
     * @param token           - TokenDetails.  Contains the details of token being sold
     * @param receivers       - Array of ListingReceiver structs.  If provided, will distribute sales proceeds to receivers accordingly.
     * @param fees            - DeliveryFees.  Contains the delivery fee configuration for the listing
     * @param markleRoot      - MerkleRoot for whitelisted listing
     */
    struct Listing {
        address payable seller;
        uint8 flags;
        uint24 totalSold;
        uint16 marketplaceBPS;
        uint16 curationBPS;
        uint16 bidCount;
        ListingDetails details;
        TokenDetails token;
        ListingReceiver[] receivers;
        DeliveryFees fees;
        bytes32 merkleRoot;
    }

    uint8 internal constant FLAG_MASK_HAS_BID = 0x1;
    uint8 internal constant FLAG_MASK_FINALIZED = 0x2;
    uint8 internal constant FLAG_MASK_TOKEN_CREATOR = 0x4;
    uint8 internal constant FLAG_MASK_ACCEPT_OFFERS = 0x8;
    uint8 internal constant FLAG_MASK_FINALIZED_LOGICALLY = 0x10;

    /**
     * @dev Listing details structure
     *
     * @param initialAmount     - The initial amount of the listing. For auctions, it represents the reserve price.
     * @param restingAmount     - The resting amount of the listing.
     * @param dutchDecAmount    - The reduction amount of the dutch auction.
     * @param type_             - Listing type
     * @param totalAvailable    - Total number of tokens available.
     * @param editionSize       - Total number of winners.
     * @param extensionInterval - Only valid for *_AUCTION types. Indicates how long an auction will extend if a bid is made within the last <extensionInterval> seconds of the auction.
     * @param minIncrementBPS   - Only valid for *_AUCTION types. Indicates the minimum bid increase required
     * @param erc20             - If not 0x0, it indicates the erc20 token accepted for this sale
     * @param startTime         - The start time of the sale.  If set to 0, startTime will be set to the first bid/purchase.
     * @param endTime           - The end time of the sale.  If startTime is 0, represents the duration of the listing upon first bid/purchase.
     */
    struct ListingDetails {
        uint256 initialAmount;
        uint256 restingAmount;
        uint256 dutchDecAmount;
        ListingType type_;
        uint24 totalAvailable;
        uint16 editionSize;
        uint16 extensionInterval;
        uint16 minIncrementBPS;
        uint16 dutchInterval;
        address erc20;
        uint48 startTime;
        uint48 endTime;
    }

    /**
     * @dev Token detail structure
     *
     * @param address_  - The contract address of the token
     * @param id        - The token id (or for a lazy asset, the asset id)
     * @param spec      - The spec of the token.  If it's a lazy token, it must be blank.
     * @param lazy      - True if token is to be lazy minted, false otherwise.  If lazy, the contract address must support ILazyDelivery
     */
    struct TokenDetails {
        uint256 id;
        address address_;
        TokenLib.Spec spec;
        bool lazy;
    }

    /**
     * @dev Fee configuration for listing
     *
     * @param deliverBPS         - Additional fee needed to deliver the token (BPS)
     * @param deliverFixed       - Additional fee needed to deliver the token (fixed)
     */
    struct DeliveryFees {
        uint16 deliverBPS;
        uint240 deliverFixed;
    }

    /**
     * Listing receiver.  The array of listing receivers must add up to 10000 BPS if provided.
     */
    struct ListingReceiver {
        address payable receiver;
        uint16 receiverBPS;
    }

    /**
     * Represents an active bid
     *
     * @param amount       - The bid amount
     * @param bidder       - The bidder
     * @param delivered    - Whether or not the token has been delivered.
     * @param settled      - Whether or not the seller has been paid
     * @param refunded     - Whether or not the bid has been refunded
     * @param timestamp    - Timestamp of bid
     */
    struct Bid {
        uint256 amount;
        address payable bidder;
        bool delivered;
        bool settled;
        bool refunded;
        uint48 timestamp;
    }

    /**
     * Represents an active offer
     *
     * @param amount        - The offer amount
     * @param timestamp     - Timestamp of offer
     * @param accepted      - Whether or not the offer was accepted (seller was paid)
     * @param erc20         - Currently unused.
     *                        Offers can only be made on the listing currency
     */
    struct Offer {
        uint200 amount;
        uint48 timestamp;
        bool accepted;
        address erc20;
    }

    /**
     * Construct a marketplace listing
     */
    function constructListing(
        address seller,
        uint40 listingId,
        Listing storage listing,
        ListingDetails calldata listingDetails,
        TokenDetails calldata tokenDetails,
        DeliveryFees calldata deliveryFees,
        ListingReceiver[] calldata listingReceivers,
        bool acceptOffers,
        bool intake
    ) public {
        require(
            tokenDetails.address_.isContract(),
            "Token address must be a contract"
        );
        require(
            listingDetails.endTime > listingDetails.startTime,
            "End time must be after start time"
        );
        require(
            listingDetails.startTime == 0 ||
                listingDetails.startTime > block.timestamp,
            "Start and end time cannot occur in the past"
        );
        require(
            listingDetails.totalAvailable % listingDetails.editionSize == 0,
            "Invalid token config"
        );
        require(
            !acceptOffers ||
                listingDetails.type_ == ListingType.INDIVIDUAL_AUCTION ||
                listingDetails.type_ == ListingType.RANKED_AUCTION ||
                listingDetails.type_ == ListingType.LINEAR_DUTCH_AUCTION ||
                listingDetails.type_ == ListingType.EXPO_DUTCH_AUCTION ||
                listingDetails.type_ == ListingType.SETTLEMENT_DUTCH_AUCTION,
            "Type cannot accept offers"
        );

        if (listingReceivers.length > 0) {
            uint256 totalBPS;
            for (uint i; i < listingReceivers.length; ) {
                listing.receivers.push(listingReceivers[i]);
                totalBPS += listingReceivers[i].receiverBPS;
                unchecked {
                    ++i;
                }
            }
            require(totalBPS == 10000, "Invalid receiver config");
        }

        if (listingDetails.type_ == ListingType.INDIVIDUAL_AUCTION) {
            require(listingDetails.editionSize == 1, "Invalid token config");
        } else if (listingDetails.type_ == ListingType.OFFERS_ONLY) {
            require(
                listingDetails.initialAmount == 0 &&
                    listingDetails.startTime > block.timestamp,
                "Invalid listing config"
            );
        }

        // Purchase types
        if (isPurchase(listingDetails.type_) || isOffer(listingDetails.type_)) {
            require(
                deliveryFees.deliverBPS == 0 &&
                    deliveryFees.deliverFixed == 0 &&
                    listingDetails.extensionInterval == 0 &&
                    listingDetails.minIncrementBPS == 0,
                "Invalid listing config"
            );
        }

        if (tokenDetails.lazy) {
            require(
                ERC165Checker.supportsInterface(
                    tokenDetails.address_,
                    type(ILazyDelivery).interfaceId
                ),
                "Lazy delivery requires token address to implement ILazyDelivery"
            );
        } else {
            require(
                listingDetails.type_ == ListingType.INDIVIDUAL_AUCTION ||
                    listingDetails.type_ == ListingType.RANKED_AUCTION ||
                    listingDetails.type_ == ListingType.LINEAR_DUTCH_AUCTION ||
                    listingDetails.type_ == ListingType.EXPO_DUTCH_AUCTION ||
                    listingDetails.type_ ==
                    ListingType.SETTLEMENT_DUTCH_AUCTION ||
                    listingDetails.type_ == ListingType.OFFERS_ONLY ||
                    listingDetails.type_ == ListingType.FIXED_PRICE,
                "Invalid type"
            );
            if (intake) {
                _intakeToken(
                    tokenDetails.spec,
                    tokenDetails.address_,
                    tokenDetails.id,
                    listingDetails.totalAvailable,
                    seller
                );
            }
        }

        // Set Listing Data
        listing.seller = payable(seller);
        listing.details = listingDetails;
        listing.token = tokenDetails;
        listing.fees = deliveryFees;

        // Token ownership check
        if (
            ERC165Checker.supportsInterface(
                tokenDetails.address_,
                type(IAdminControl).interfaceId
            ) && IAdminControl(tokenDetails.address_).isAdmin(seller)
        ) {
            listing.flags |= FLAG_MASK_TOKEN_CREATOR;
        } else {
            try IOwnable(tokenDetails.address_).owner() returns (
                address owner
            ) {
                if (owner == seller) listing.flags |= FLAG_MASK_TOKEN_CREATOR;
            } catch {}
        }

        if (acceptOffers) {
            listing.flags |= FLAG_MASK_ACCEPT_OFFERS;
        }

        _emitCreateListing(listingId, listing);
    }

    function _emitCreateListing(
        uint40 listingId,
        Listing storage listing
    ) private {
        emit CreateListing(
            listingId,
            listing.marketplaceBPS,
            uint8(listing.details.type_),
            listing.details.totalAvailable,
            listing.details.editionSize,
            listing.details.startTime,
            listing.details.endTime,
            listing.details.initialAmount,
            listing.details.extensionInterval,
            listing.details.minIncrementBPS,
            listing.details.erc20
        );
        emit CreateListingTokenDetails(
            listingId,
            listing.token.id,
            listing.token.address_,
            uint8(listing.token.spec),
            listing.token.lazy
        );
        if (listing.fees.deliverBPS > 0 || listing.fees.deliverFixed > 0) {
            emit CreateListingFees(
                listingId,
                listing.fees.deliverBPS,
                listing.fees.deliverFixed
            );
        }
    }

    function _intakeToken(
        TokenLib.Spec tokenSpec,
        address tokenAddress,
        uint256 tokenId,
        uint256 tokensToTransfer,
        address from
    ) private {
        if (tokenSpec == TokenLib.Spec.ERC721) {
            require(
                tokensToTransfer == 1,
                "ERC721 invalid number of tokens to transfer"
            );
            TokenLib._erc721Transfer(
                tokenAddress,
                tokenId,
                from,
                address(this)
            );
        } else if (tokenSpec == TokenLib.Spec.ERC1155) {
            TokenLib._erc1155Transfer(
                tokenAddress,
                tokenId,
                tokensToTransfer,
                from,
                address(this)
            );
        } else {
            revert("Unsupported token spec");
        }
    }

    function isAuction(ListingType type_) internal pure returns (bool) {
        return (type_ == ListingType.INDIVIDUAL_AUCTION ||
            type_ == ListingType.RANKED_AUCTION ||
            type_ == ListingType.SETTLEMENT_DUTCH_AUCTION);
    }

    function isPurchase(ListingType type_) internal pure returns (bool) {
        return (type_ == ListingType.FIXED_PRICE ||
            type_ == ListingType.LINEAR_DUTCH_AUCTION ||
            type_ == ListingType.EXPO_DUTCH_AUCTION);
    }

    function isOffer(ListingType type_) internal pure returns (bool) {
        return (type_ == ListingType.OFFERS_ONLY);
    }

    function canOffer(
        ListingType type_,
        uint8 listingFlags
    ) internal pure returns (bool) {
        // Can only make an offer if:
        // 1. Listing is an OFFERS_ONLY type
        // 2. Listing is an INDIVIDUAL_AUCTION that has offers enabled and no bids
        return (isOffer(type_) ||
            (isAuction(type_) &&
                (listingFlags & FLAG_MASK_ACCEPT_OFFERS) != 0 &&
                !hasBid(listingFlags)));
    }

    function hasBid(uint8 listingFlags) internal pure returns (bool) {
        return listingFlags & FLAG_MASK_HAS_BID != 0;
    }

    function isFinalized(uint8 listingFlags) internal pure returns (bool) {
        return listingFlags & FLAG_MASK_FINALIZED != 0;
    }

    function isFinalizedLogically(uint8 listingFlags) internal pure returns (bool) {
        return listingFlags & FLAG_MASK_FINALIZED_LOGICALLY != 0;
    }

    function sellerIsTokenCreator(
        uint8 listingFlags
    ) internal pure returns (bool) {
        return listingFlags & FLAG_MASK_TOKEN_CREATOR != 0;
    }

    function modifyListing(
        uint40 listingId,
        Listing storage listing,
        uint256 initialAmount,
        uint48 startTime,
        uint48 endTime
    ) public {
        require(listing.seller == msg.sender, "Permission denied");
        require(endTime > startTime, "End time must be after start time");
        require(
            startTime == 0 ||
                (startTime == listing.details.startTime &&
                    endTime > block.timestamp) ||
                startTime > block.timestamp,
            "Start and end time cannot occur in the past"
        );
        require(
            !isFinalized(listing.flags) &&
                ((!isAuction(listing.details.type_) &&
                    listing.totalSold == 0) ||
                    (isAuction(listing.details.type_) &&
                        listing.bidCount == 0)),
            "Cannot modify listing that has already started or completed"
        );
        listing.details.initialAmount = initialAmount;
        listing.details.startTime = startTime;
        listing.details.endTime = endTime;

        emit ModifyListing(listingId, initialAmount, startTime, endTime);
    }
}