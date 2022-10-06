// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./libs/MarketplaceLib.sol";

/**
 * Core Marketplace interface
 */     
interface IMarketplaceCore {

    event MarketplaceEnabled(address requestor, bool value);
    event MarketplaceFees(address requestor, uint16 feeBPS, uint16 referrerBPS);
    event MarketplaceSellerRegistry(address requestor, address registry);
    event MarketplaceWithdraw(address requestor, address erc20, uint256 amount, address receiver);
    event MarketplaceWithdrawEscrow(address requestor, address erc20, uint256 amount);
    event MarketplaceRoyaltyEngineUpdate(address royaltyEngineV1);

    /**
     * @dev Listing structure
     *
     * @param id              - id of listing
     * @param seller          - the selling party
     * @param finalized       - Whether or not this listing has completed accepting bids/purchases
     * @param totalSold       - total number of items sold.  This IS NOT the number of sales.  Number of sales is totalSold/details.totalPerSale.
     * @param marketplaceBPS  - Marketplace fee BPS
     * @param referrerBPS     - Referrer BPS
     * @param details         - ListingDetails.  Contains listing configuration
     * @param token           - TokenDetails.  Contains the details of token being sold
     * @param receivers       - Array of ListingReceiver structs.  If provided, will distribute sales proceeds to receivers accordingly.
     * @param fees            - DeliveryFees.  Contains the delivery fee configuration for the listing
     * @param bid             - Active bid.  Only valid for INDIVIDUAL_AUCTION (1 bid)
     */
    struct Listing {
        uint256 id;
        address payable seller;
        bool finalized;
        uint24 totalSold;
        uint16 marketplaceBPS;
        uint16 referrerBPS;
        MarketplaceLib.ListingDetails details;
        MarketplaceLib.TokenDetails token;
        MarketplaceLib.ListingReceiver[] receivers;
        MarketplaceLib.DeliveryFees fees;
        MarketplaceLib.Bid bid;
    }

    /**
     * @dev Set marketplace fee
     */
    function setFees(uint16 marketplaceFeeBPS, uint16 marketplaceReferrerBPS) external;

    /**
     * @dev Set marketplace enabled
     */
    function setEnabled(bool enabled) external;

    /**
     * @dev Set marketplace seller registry
     */
    function setSellerRegistry(address registry) external;

    /**
     * @dev See RoyaltyEngineV1 location. Can only be set once
     */
    function setRoyaltyEngineV1(address royaltyEngineV1) external;

    /**
     * @dev Withdraw from treasury
     */
    function withdraw(uint256 amount, address payable receiver) external;

    /**
     * @dev Withdraw from treasury
     */
    function withdraw(address erc20, uint256 amount, address payable receiver) external;

    /**
     * @dev Withdraw from escrow
     */
    function withdrawEscrow(uint256 amount) external;

    /**
     * @dev Withdraw from escrow
     */
    function withdrawEscrow(address erc20, uint256 amount) external;

    /**
     * @dev Create listing
     */
    function createListing(MarketplaceLib.ListingDetails calldata listingDetails, MarketplaceLib.TokenDetails calldata tokenDetails, MarketplaceLib.DeliveryFees calldata deliveryFees, MarketplaceLib.ListingReceiver[] calldata listingReceivers, bool enableReferrer, bytes calldata data) external returns (uint256);

    /**
     * @dev Modify listing
     */
    function modifyListing(uint40 listingId, uint256 initialAmount, uint48 startTime, uint48 endTime) external;

    /**
     * @dev Purchase a listed item
     */
    function purchase(uint40 listingId) external payable;
    function purchase(uint40 listingId, bytes calldata data) external payable;

    /**
     * @dev Purchase a listed item (with a referrer)
     */
    function purchase(address referrer, uint40 listingId) external payable;
    function purchase(address referrer, uint40 listingId, bytes calldata data) external payable;

    /**
     * @dev Purchase a listed item
     */
    function purchase(uint40 listingId, uint24 count) external payable;
    function purchase(uint40 listingId, uint24 count, bytes calldata data) external payable;

    /**
     * @dev Purchase a listed item (with a referrer)
     */
    function purchase(address referrer, uint40 listingId, uint24 count) external payable;
    function purchase(address referrer, uint40 listingId, uint24 count, bytes calldata data) external payable;

    /**
     * @dev Bid on a listed item
     */
    function bid(uint40 listingId, bool increase) external payable;
    function bid(uint40 listingId, bool increase, bytes calldata data) external payable;

    /**
     * @dev Bid on a listed item (with a referrer)
     */
    function bid(address payable referrer, uint40 listingId, bool increase) external payable;
    function bid(address payable referrer, uint40 listingId, bool increase, bytes calldata data) external payable;

    /**
     * @dev Bid on a listed item
     */
    function bid(uint40 listingId, uint256 bidAmount, bool increase) external;
    function bid(uint40 listingId, uint256 bidAmount, bool increase, bytes calldata data) external;

    /**
     * @dev Bid on a listed item (with a referrer)
     */
    function bid(address payable referrer, uint40 listingId, uint256 bidAmount, bool increase) external;
    function bid(address payable referrer, uint40 listingId, uint256 bidAmount, bool increase, bytes calldata data) external;

    /**
     * @dev Collect proceeds of sale.  Only valid for non-lazy auctions where the asset
     * is in escrow
     */
    function collect(uint40 listingId) external;

    /**
     * @dev Finalize a listed item (post-purchase)
     */
    function finalize(uint40 listingId) external payable;
    
    /**
     * @dev Cancel listing
     */
    function cancel(uint40 listingId, uint16 holdbackBPS) external;
    
    /**
     * @dev Deliver a finalized bid purchase
     */
    function deliver(uint40 listingId, uint256 bidIndex) external payable;

    /**
     * @dev Get listing details
     */
    function getListing(uint40 listingId) external view returns(Listing memory);

    /**
     * @dev Get the listing's current price
     */
    function getListingCurrentPrice(uint40 listingId) external view returns(uint256);

    /**
     * @dev Get the listing's deliver fee
     */
    function getListingDeliverFee(uint40 listingId, uint256 price) external view returns(uint256);

    /**
     * @dev Get the total listing price for multiple items
     */
    function getListingTotalPrice(uint40 listingId, uint24 count) external view returns(uint256);

    /**
     * @dev Returns bids of a listing. No ordering guarantees
     */
    function getBids(uint40 listingId) external view returns(MarketplaceLib.Bid[] memory);
}