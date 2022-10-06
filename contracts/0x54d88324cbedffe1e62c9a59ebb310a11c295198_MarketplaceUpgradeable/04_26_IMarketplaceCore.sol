// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./libs/MarketplaceLib.sol";

/**
 * Core Marketplace interface
 */     
interface IMarketplaceCore {

    event MarketplaceEnabled(address requestor, bool value);
    event MarketplaceFeeBPS(address requestor, uint16 bps);
    event MarketplaceSellerRegistry(address requestor, address registry);
    event MarketplaceTokenReceiver(address requestor, address receiver);
    event MarketplaceWithdraw(address requestor, address erc20, uint256 amount, address receiver);
    event MarketplaceWithdrawEscrow(address requestor, address erc20, uint256 amount);

    /**
     * @dev Set marketplace fee
     */
    function setMarketplaceFeeBPS(uint16 marketplaceFeeBPS) external;

    /**
     * @dev Set marketplace enabled
     */
    function setEnabled(bool enabled) external;

    /**
     * @dev Set marketplace seller registry
     */
    function setSellerRegistry(address registry) external;

    /** 
     * @dev Set the marketplace's token receiver
     */
    function setTokenReceiver(address tokenReceiver) external;

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
    function createListing(MarketplaceLib.ListingDetails calldata listingDetails, MarketplaceLib.TokenDetails calldata tokenDetails, MarketplaceLib.FeeData calldata feeData, MarketplaceLib.ListingReceiver[] calldata listingReceivers) external returns (uint256);

    /**
     * @dev Purchase a listed item
     */
    function purchase(uint256 listingId) external payable;

    /**
     * @dev Purchase a listed item (with a referrer)
     */
    function purchase(address referrer, uint256 listingId) external payable;

    /**
     * @dev Bid on a listed item
     */
    function bid(uint256 listingId, bool increase) external payable;

    /**
     * @dev Bid on a listed item (with a referrer)
     */
    function bid(address payable referrer, uint256 listingId, bool increase) external payable;

    /**
     * @dev Bid on a listed item
     */
    function bid(uint256 listingId, uint256 bidAmount, bool increase) external;

    /**
     * @dev Bid on a listed item (with a referrer)
     */
    function bid(address payable referrer, uint256 listingId, uint256 bidAmount, bool increase) external;

    /**
     * @dev Collect proceeds of sale.  Only valid for non-lazy auctions where the asset
     * is in escrow
     */
    function collect(uint256 listingId) external;

    /**
     * @dev Finalize a listed item (post-purchase)
     */
    function finalize(uint256 listingId) external payable;
    
    /**
     * @dev Cancel listing
     */
    function cancel(uint256 listingId, uint16 holdbackBPS) external;
    
    /**
     * @dev Deliver a finalized bid purchase
     */
    function deliver(uint256 listingId, uint256 bidIndex) external payable;

    /**
     * @dev Get listing details
     */
    function getListing(uint256 listingId) external view returns(MarketplaceLib.Listing memory);

    /**
     * @dev Get the listing's current price
     */
    function getListingCurrentPrice(uint256 listingId) external view returns(uint256);

    /**
     * @dev Get the listing's deliver fee
     */
    function getListingDeliverFee(uint256 listingId, uint256 price) external view returns(uint256);

    /**
     * @dev Returns bids of a listing. No ordering guarantees
     */
    function getBids(uint256 listingId) external view returns(MarketplaceLib.Bid[] memory);
}