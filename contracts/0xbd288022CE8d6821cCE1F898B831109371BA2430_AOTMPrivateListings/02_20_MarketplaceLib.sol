// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "@manifoldxyz/libraries-solidity/contracts/access/IAdminControl.sol";

import "../IIdentityVerifier.sol";
import "../ILazyDelivery.sol";
import "../IPriceEngine.sol";

import "./BidTreeLib.sol";
import "./TokenLib.sol";

/**
 * Interface for Ownable contracts
 */
interface IOwnable {
    function owner() external view returns(address);
}

/**
 * @dev Marketplace libraries
 */
library MarketplaceLib {
    using AddressUpgradeable for address;
    using BidTreeLib for BidTreeLib.BidTree;

    // Events
    event CreateListing(uint40 indexed listingId, uint16 marketplaceBPS, uint16 referrerBPS, uint8 listingType, uint24 totalAvailable, uint24 totalPerSale, uint48 startTime, uint48 endTime, uint256 initialAmount, uint16 extensionInterval, uint16 minIncrementBPS, address erc20, address identityVerifier);
    event CreateListingTokenDetails(uint40 indexed listingId, uint256 id, address address_, uint8 spec, bool lazy);
    event CreateListingFees(uint40 indexed listingId, uint16 deliverBPS, uint240 deliverFixed);

    event PurchaseEvent(uint40 indexed listingId, address referrer, address buyer, uint24 count, uint256 amount);
    event BidEvent(uint40 indexed listingId, address referrer, address bidder, uint256 amount);
    event ModifyListing(uint40 indexed listingId, uint256 initialAmount, uint48 startTime, uint48 endTime);
    event CancelListing(uint40 indexed listingId, address requestor, uint16 holdbackBPS);

    // Listing types
    enum ListingType {
        INVALID,
        INDIVIDUAL_AUCTION,
        FIXED_PRICE,
        DYNAMIC_PRICE,
        RANKED_AUCTION
    }

    /**
     * @dev Listing structure
     *
     * @param seller          - the selling party
     * @param flags           - bit flag (hasBid, finalized, tokenCreator).  See FLAG_MASK_*
     * @param totalSold       - total number of items sold.  This IS NOT the number of sales.  Number of sales is totalSold/details.totalPerSale.
     * @param marketplaceBPS  - Marketplace fee BPS
     * @param referrerBPS     - Fee BPS for referrer if there is one
     * @param details         - ListingDetails.  Contains listing configuration
     * @param token           - TokenDetails.  Contains the details of token being sold
     * @param receivers       - Array of ListingReceiver structs.  If provided, will distribute sales proceeds to receivers accordingly.
     * @param bid             - Active bid.  Only valid for INDIVIDUAL_AUCTION (1 bid)
     * @param fees            - DeliveryFees.  Contains the delivery fee configuration for the listing
     */
    struct Listing {
        address payable seller;
        uint8 flags;
        uint24 totalSold;
        uint16 marketplaceBPS;
        uint16 referrerBPS;
        ListingDetails details;
        TokenDetails token;
        ListingReceiver[] receivers;
        Bid bid;
        DeliveryFees fees;
    }

    uint8 internal constant FLAG_MASK_HAS_BID = 0x1;
    uint8 internal constant FLAG_MASK_FINALIZED = 0x2;
    uint8 internal constant FLAG_MASK_TOKEN_CREATOR = 0x4;

    /**
     * @dev Listing details structure
     *
     * @param initialAmount     - The initial amount of the listing. For auctions, it represents the reserve price.  For DYNAMIC_PRICE listings, it must be 0.
     * @param type_             - Listing type
     * @param totalAvailable    - Total number of tokens available.  Must be divisible by totalPerSale. For INDIVIDUAL_AUCTION, totalAvailable must equal totalPerSale
     * @param totalPerSale      - Number of tokens the buyer will get per purchase.  Must be 1 if it is a lazy token
     * @param extensionInterval - Only valid for *_AUCTION types. Indicates how long an auction will extend if a bid is made within the last <extensionInterval> seconds of the auction.
     * @param minIncrementBPS   - Only valid for *_AUCTION types. Indicates the minimum bid increase required
     * @param erc20             - If not 0x0, it indicates the erc20 token accepted for this sale
     * @param identityVerifier  - If not 0x0, it indicates the buyers should be verified before any bid or purchase
     * @param startTime         - The start time of the sale.  If set to 0, startTime will be set to the first bid/purchase.
     * @param endTime           - The end time of the sale.  If startTime is 0, represents the duration of the listing upon first bid/purchase.
     */
    struct ListingDetails {
        uint256 initialAmount;
        ListingType type_;
        uint24 totalAvailable;
        uint24 totalPerSale;
        uint16 extensionInterval;
        uint16 minIncrementBPS;
        address erc20;
        address identityVerifier;
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
     * @param referrer     - The referrer
     * @param bidder       - The bidder
     * @param delivered    - Whether or not the token has been delivered.
     * @param settled      - Whether or not the seller has been paid
     * @param refunded     - Whether or not the bid has been refunded
     */
    struct Bid {
        uint256 amount;
        address payable bidder;
        bool delivered;
        bool settled;
        bool refunded;
        uint48 timestamp;
        address payable referrer;
    }

    /**
     * Construct a marketplace listing
     */
    function constructListing(address seller, uint40 listingId, Listing storage listing, ListingDetails calldata listingDetails, TokenDetails calldata tokenDetails, DeliveryFees calldata deliveryFees, ListingReceiver[] calldata listingReceivers, bool intake) public {
        require(tokenDetails.address_.isContract(), "Token address must be a contract");
        require(listingDetails.endTime > listingDetails.startTime, "End time must be after start time");
        require(listingDetails.startTime == 0 || listingDetails.startTime > block.timestamp, "Start and end time cannot occur in the past");
        require(listingDetails.totalAvailable % listingDetails.totalPerSale == 0, "Invalid token config");
        
        if (listingDetails.identityVerifier != address(0)) {
            require(ERC165Checker.supportsInterface(listingDetails.identityVerifier, type(IIdentityVerifier).interfaceId), "Misconfigured verifier");
        }
        
        if (listingReceivers.length > 0) {
            uint256 totalBPS;
            for (uint i = 0; i < listingReceivers.length; i++) {
                listing.receivers.push(listingReceivers[i]);
                totalBPS += listingReceivers[i].receiverBPS;
            }
            require(totalBPS == 10000, "Invalid receiver config");
        }

        if (listingDetails.type_ == ListingType.INDIVIDUAL_AUCTION) {
            require(listingDetails.totalAvailable == listingDetails.totalPerSale, "Invalid token config");
        } else if (listingDetails.type_ == ListingType.DYNAMIC_PRICE) {
            require(tokenDetails.lazy && listingDetails.initialAmount == 0, "Invalid listing config");
            require(ERC165Checker.supportsInterface(tokenDetails.address_, type(IPriceEngine).interfaceId), "Lazy delivered dynamic price items requires token address to implement IPriceEngine");
        } else if (listingDetails.type_ == ListingType.RANKED_AUCTION) {
            require(tokenDetails.lazy && listingDetails.totalAvailable <= 256, "Invalid listing config");
        }

        // Purchase types        
        if (listingDetails.type_ == ListingType.FIXED_PRICE || listingDetails.type_ == ListingType.DYNAMIC_PRICE) {
            require(deliveryFees.deliverBPS == 0 && deliveryFees.deliverFixed == 0 && listingDetails.extensionInterval == 0 && listingDetails.minIncrementBPS == 0, "Invalid listing config");
        }

        if (tokenDetails.lazy) {
            require(listingDetails.totalPerSale == 1, "Invalid token config");
            require(ERC165Checker.supportsInterface(tokenDetails.address_, type(ILazyDelivery).interfaceId), "Lazy delivery requires token address to implement ILazyDelivery");
        } else {
            require(listingDetails.type_ == ListingType.INDIVIDUAL_AUCTION || listingDetails.type_ == ListingType.FIXED_PRICE, "Invalid type");
            if (intake) {
                _intakeToken(tokenDetails.spec, tokenDetails.address_, tokenDetails.id, listingDetails.totalAvailable, seller);
            }
        }

        // Set Listing Data
        listing.seller = payable(seller);
        listing.details = listingDetails;
        listing.token = tokenDetails;
        listing.fees = deliveryFees;

        // Token ownership check
        if (ERC165Checker.supportsInterface(tokenDetails.address_, type(IAdminControl).interfaceId)
                && IAdminControl(tokenDetails.address_).isAdmin(seller)) {
            listing.flags |= FLAG_MASK_TOKEN_CREATOR;
        } else {
            try IOwnable(tokenDetails.address_).owner() returns (address owner) {
                if (owner == seller) listing.flags |= FLAG_MASK_TOKEN_CREATOR;
            } catch {}
        }
        
        
        _emitCreateListing(listingId, listing);

    }

    function _emitCreateListing(uint40 listingId, Listing storage listing) private {
        emit CreateListing(listingId, listing.marketplaceBPS, listing.referrerBPS, uint8(listing.details.type_), listing.details.totalAvailable, listing.details.totalPerSale, listing.details.startTime, listing.details.endTime, listing.details.initialAmount, listing.details.extensionInterval, listing.details.minIncrementBPS, listing.details.erc20, listing.details.identityVerifier);
        emit CreateListingTokenDetails(listingId, listing.token.id, listing.token.address_, uint8(listing.token.spec), listing.token.lazy);
        if (listing.fees.deliverBPS > 0 || listing.fees.deliverFixed > 0) {
            emit CreateListingFees(listingId, listing.fees.deliverBPS, listing.fees.deliverFixed);
        }
    }

    function _intakeToken(TokenLib.Spec tokenSpec, address tokenAddress, uint256 tokenId, uint256 tokensToTransfer, address from) private {
        if (tokenSpec == TokenLib.Spec.ERC721) {
            require(tokensToTransfer == 1, "ERC721 invalid number of tokens to transfer");
            TokenLib._erc721Transfer(tokenAddress, tokenId, from, address(this));
        } else if (tokenSpec == TokenLib.Spec.ERC1155) {
            TokenLib._erc1155Transfer(tokenAddress, tokenId, tokensToTransfer, from, address(this));
        } else {
            revert("Unsupported token spec");
        }
    }

    function modifyListing(uint40 listingId, Listing storage listing, uint256 initialAmount, uint48 startTime, uint48 endTime) public {
        require(listing.seller == msg.sender, "Permission denied");
        require(endTime > startTime, "End time must be after start time");
        require(startTime == 0 || startTime > block.timestamp, "Start and end time cannot occur in the past");
        require(listing.details.startTime == 0 || (block.timestamp < listing.details.startTime && (listing.flags & MarketplaceLib.FLAG_MASK_FINALIZED) == 0), "Cannot modify listing that has already started or completed");
        require(listing.details.type_ != MarketplaceLib.ListingType.DYNAMIC_PRICE || initialAmount == 0, "Invalid listing config");
        listing.details.initialAmount = initialAmount;
        listing.details.startTime = startTime;
        listing.details.endTime = endTime;

        emit ModifyListing(listingId, initialAmount, startTime, endTime);
    }

    function getBids(uint40 listingId, Listing storage listing,  mapping(uint40 => BidTreeLib.BidTree) storage listingBidTree, mapping (uint40 => address[]) storage listingBidTreeFinalOrder) public view returns(Bid[] memory bids) {
        if ((listing.flags & MarketplaceLib.FLAG_MASK_HAS_BID) != 0) {
            if (listing.details.type_ == MarketplaceLib.ListingType.RANKED_AUCTION) {
                BidTreeLib.BidTree storage bidTree = listingBidTree[listingId];
                if ((listing.flags & MarketplaceLib.FLAG_MASK_FINALIZED) == 0) {
                    bids = new MarketplaceLib.Bid[](bidTree.size);
                    uint256 index = 0;
                    address key = bidTree.first();
                    while (key != address(0)) {
                        BidTreeLib.Bid memory bid_ = bidTree.getBid(key);
                        bids[index] = MarketplaceLib.Bid({amount:bid_.amount, bidder:payable(key), delivered:bid_.delivered, settled:bid_.settled, refunded:bid_.refunded, timestamp:bid_.timestamp, referrer:payable(address(0))});
                        key = bidTree.next(key);
                        index++;
                    }
                } else {
                    address[] storage bidTreeFinalOrder = listingBidTreeFinalOrder[listingId];
                    bids = new MarketplaceLib.Bid[](bidTreeFinalOrder.length);
                    for (uint i = 0; i < bidTreeFinalOrder.length; i++) {
                        address key = bidTreeFinalOrder[i];
                        BidTreeLib.Bid memory bid_ = bidTree.getBid(key);
                        bids[i] = MarketplaceLib.Bid({amount:bid_.amount, bidder:payable(key), delivered:bid_.delivered, settled:bid_.settled, refunded:bid_.refunded, timestamp:bid_.timestamp, referrer:payable(address(0))});
                    }
                }
            } else {
                bids = new MarketplaceLib.Bid[](1);
                bids[0] = listing.bid;
            }
        }
    }

}