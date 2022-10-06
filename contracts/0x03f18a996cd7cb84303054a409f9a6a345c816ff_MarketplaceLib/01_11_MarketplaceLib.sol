// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../IIdentityVerifier.sol";
import "../ILazyDelivery.sol";
import "../IMarketplaceTokenReceiver.sol";
import "../IPriceEngine.sol";

import "./IRoyalty.sol";
import "./TokenLib.sol";

/**
 * @dev Marketplace libraries
 */
library MarketplaceLib {
    using AddressUpgradeable for address;

    // Events
    event CreateListing(uint256 indexed listingId, uint256 listingType, uint256 totalAvailable, uint256 totalPerSale, uint48 startTime, uint48 endTime, uint256 initialAmount, uint48 extensionInterval, uint16 minIncrementBPS, address erc20, address identityVerifier);
    event CreateListingTokenDetails(uint256 indexed listingId, string spec, address address_, uint256 id, bool lazy);
    event CreateListingFees(uint256 indexed listingId, uint16 marketplaceBPS, uint16 referrerBPS, uint16 deliverBPS, uint256 deliverFixed);

    event PurchaseEvent(uint256 indexed listingId, address referrer, address buyer, uint256 amount);
    event BidEvent(uint256 indexed listingId, address referrer, address bidder, uint256 amount);
    event CancelListing(uint256 indexed listingId, address requestor, uint16 holdbackBPS);

    // Listing construction data
    struct FeeData {
         uint16 referrerBPS;
         uint16 deliverBPS;
         uint256 deliverFixed;
    }

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
     * @param id              - id of listing
     * @param seller          - the selling party
     * @param bidLowestIndex  - The index of the bid with the lowest amount.  Only valid for RANKED_AUCTION.
     * @param hasBid          - Whether or not the listing has at least one bid
     * @param finalized       - whether or not this listing has completed accepting bids/purchases
     * @param totalSold       - total number of items sold.  This IS NOT the number of sales.  Number of sales is totalSold/details.totalPerSale.
     * @param details         - ListingDetails.  Contains listing configuration
     * @param token           - TokenDetails.  Contains the details of token being sold
     * @param fees            - Fees.  Contains the fee configuration for the listing
     * @param receivers       - Array of ListingReceiver structs.  If provided, will distribute sales proceeds to receivers accordingly.
     * @param bid             - Active bid.  Only valid for INDIVIDUAL_AUCTION (1 bid)
     */
    struct Listing {
         uint256 id;
         address payable seller;
         uint16 bidLowestIndex;
         bool hasBid;
         bool finalized;
         uint256 totalSold;
         ListingDetails details;
         TokenDetails token;
         Fees fees;
         ListingReceiver[] receivers;
         Bid bid;
     }

     /**
      * @dev Listing details structure
      *
      * @param type_             - Listing type
      * @param totalAvailable    - Total number of tokens available.  Must be divisible by totalPerSale. For INDIVIDUAL_AUCTION, totalAvailable must equal totalPerSale
      * @param totalPerSale      - Number of tokens the buyer will get per purchase.  Must be 1 if it is a lazy token
      * @param initialAmount     - The initial amount of the listing. For auctions, it represents the reserve price.  For DYNAMIC_PRICE listings, it must be 0.
      * @param extensionInterval - Only valid for *_AUCTION types. Indicates how long an auction will extend if a bid is made within the last <extensionInterval> seconds of the auction.
      * @param minIncrementBPS   - Only valid for *_AUCTION types. Indicates the minimum bid increase required
      * @param erc20             - If not 0x0, it indicates the erc20 token accepted for this sale
      * @param identityVerifier  - If not 0x0, it indicates the buyers should be verified before any bid or purchase
      * @param startTime         - The start time of the sale.  If set to 0, startTime will be set to the first bid/purchase.
      * @param endTime           - The end time of the sale.  If startTime is 0, represents the duration of the listing upon first bid/purchase.
      */
     struct ListingDetails {
         ListingType type_;
         uint256 totalAvailable;
         uint256 totalPerSale;
         uint256 initialAmount;
         uint48 extensionInterval;
         uint16 minIncrementBPS;
         address erc20;
         address identityVerifier;

         uint48 startTime;
         uint48 endTime;
     }

     /**
      * @dev Token detail structure
      *
      * @param spec      - The spec of the token.  If it's a lazy token, it must be blank.
      * @param address_  - The contract address of the token
      * @param id        - The token id (or for a lazy asset, the asset id)
      * @param lazy      - True if token is to be lazy minted, false otherwise.  If lazy, the contract address must support ILazyDelivery
      */
     struct TokenDetails {
         string spec;
         address address_;
         uint256 id;
         bool lazy;
     }

     /**
      * @dev Fee configuration for listing
      *
      * @param marketplaceBPS     - Marketplace fee BPS
      * @param referrerBPS        - Fee BPS for referrer if there is one
      * @param deliverBPS         - Additional fee needed to deliver the token (BPS)
      * @param deliverFixed       - Additional fee needed to deliver the token (fixed)
      */
     struct Fees {
         uint16 marketplaceBPS;
         uint16 referrerBPS;
         uint16 deliverBPS;
         uint256 deliverFixed;
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
      * @param referrer     - The referrer (no referrer is address(1))
      * @param bidder       - The bidder (no bidder is address(1))
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
    function constructListing(Listing storage listing, address tokenReceiver, uint16 marketplaceFeeBPS, ListingDetails calldata listingDetails, TokenDetails calldata tokenDetails, FeeData calldata feeData, ListingReceiver[] calldata listingReceivers) public {

        Fees memory fees = Fees( marketplaceFeeBPS, feeData.referrerBPS, feeData.deliverBPS, feeData.deliverFixed);

        require((fees.marketplaceBPS + fees.referrerBPS) < 10000, "Invalid fee config");
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
            // Pushing values of 1 to offload the initial storage cost to constructor
            listing.bid = Bid(1, payable(address(1)), false, false, false, uint48(1), payable(address(1)));
        }

        if (listingDetails.type_ == ListingType.DYNAMIC_PRICE) {
            require(tokenDetails.lazy && listingDetails.initialAmount == 0, "Invalid listing config");
            require(ERC165Checker.supportsInterface(tokenDetails.address_, type(IPriceEngine).interfaceId), "Lazy delivered dynamic price items requires token address to implement IPriceEngine");
        }

        if (listingDetails.type_ == ListingType.RANKED_AUCTION) {
            require(tokenDetails.lazy && listingDetails.totalAvailable < 1024, "Invalid listing config");
        }

        // Purchase types        
        if (listingDetails.type_ == ListingType.FIXED_PRICE || listingDetails.type_ == ListingType.DYNAMIC_PRICE) {
            require(fees.deliverBPS == 0 && fees.deliverFixed == 0 && listingDetails.extensionInterval == 0 && listingDetails.minIncrementBPS == 0, "Invalid listing config");
        }

        if (tokenDetails.lazy) {
            require(listingDetails.totalPerSale == 1, "Invalid token config");
            require(ERC165Checker.supportsInterface(tokenDetails.address_, type(ILazyDelivery).interfaceId), "Lazy delivery requires token address to implement ILazyDelivery");
        } else {
            require(listingDetails.type_ == ListingType.INDIVIDUAL_AUCTION || listingDetails.type_ == ListingType.FIXED_PRICE, "Invalid type");
            _intakeToken(tokenReceiver, tokenDetails.spec, tokenDetails.address_, tokenDetails.id, listingDetails.totalAvailable, msg.sender);
        }

        // Set Listing Data
        listing.seller = payable(msg.sender);
        listing.details = listingDetails;
        listing.token = tokenDetails;
        listing.fees = fees;


        _emitCreateListing(listing);

    }

    function _emitCreateListing(Listing storage listing) private {
        emit CreateListing(listing.id, uint256(listing.details.type_), listing.details.totalAvailable, listing.details.totalPerSale, listing.details.startTime, listing.details.endTime, listing.details.initialAmount, listing.details.extensionInterval, listing.details.minIncrementBPS, listing.details.erc20, listing.details.identityVerifier);
        emit CreateListingTokenDetails(listing.id, listing.token.spec, listing.token.address_, listing.token.id, listing.token.lazy);
        emit CreateListingFees(listing.id, listing.fees.marketplaceBPS, listing.fees.referrerBPS, listing.fees.deliverBPS, listing.fees.deliverFixed);
    }

    function _intakeToken(address tokenReceiver, string memory tokenSpec, address tokenAddress, uint256 tokenId, uint256 tokensToTransfer, address from) private {
        if (keccak256(bytes(tokenSpec)) == TokenLib._erc721bytes32) {
            require(tokensToTransfer == 1, "ERC721 invalid number of tokens to transfer");
            address currentOwner = IERC721(tokenAddress).ownerOf(tokenId);
            require(from == currentOwner, "Invalid owner");
            TokenLib._erc721Transfer(tokenAddress, tokenId, from, address(this));
        } else if (keccak256(bytes(tokenSpec)) == TokenLib._erc1155bytes32) {
            require(tokenReceiver != address(0), "Receiver not configured");
            IMarketplaceTokenReceiver(tokenReceiver).decrementERC1155(from, tokenAddress, tokenId, tokensToTransfer);
        } else {
            revert("Unsupported token spec");
        }
    }
}