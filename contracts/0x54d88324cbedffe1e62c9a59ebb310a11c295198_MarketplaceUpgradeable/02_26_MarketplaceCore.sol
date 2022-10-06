// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./IMarketplaceCore.sol";
import "./IPriceEngine.sol";
import "./IMarketplaceSellerRegistry.sol";

import "./libs/MarketplaceLib.sol";
import "./libs/SettlementLib.sol";
import "./libs/BidTreeLib.sol";

abstract contract MarketplaceCore is ReentrancyGuard, IMarketplaceCore {
    using EnumerableSet for EnumerableSet.AddressSet;
    using BidTreeLib for BidTreeLib.BidTree;

    bool private _enabled;
    address private _sellerRegistry;
     
    uint256 private _listingCounter;
    mapping (uint256 => MarketplaceLib.Listing) private _listings;
    mapping (uint256 => BidTreeLib.BidTree) private _listingBidTree;
    mapping (uint256 => address[]) private _listingBidTreeFinalOrder;
    mapping (address => mapping (address => uint256)) private _escrow;

    // Marketplace fee
    uint16 private _feeBPS;
    mapping (address => uint256) _feesCollected;

    address private _tokenReceiver;

    /**
     * @dev Set enabled
     */
    function _setEnabled(bool enabled) internal {
        _enabled = enabled;
        emit MarketplaceEnabled(msg.sender, enabled);
    }

    /**
     * @dev Set seller registry
     */
    function _setSellerRegistry(address registry) internal {
        require(ERC165Checker.supportsInterface(registry, type(IMarketplaceSellerRegistry).interfaceId), "Invalid registry");
        _sellerRegistry = registry;
        emit MarketplaceSellerRegistry(msg.sender, registry);
    }

    /**
     * @dev Set marketplace fee basis points
     */
    function _setMarketplaceFeeBPS(uint16 feeBPS) internal {
        require(feeBPS < 10000, "Invalid fee config");
        _feeBPS = feeBPS;
        emit MarketplaceFeeBPS(msg.sender, feeBPS);
    }

    /**
     * @dev Set the marketplace's token receiver
     */
    function _setTokenReceiver(address tokenReceiver) internal {
        _tokenReceiver = tokenReceiver;
        emit MarketplaceTokenReceiver(msg.sender, tokenReceiver);
    }

    /**
     * @dev Withdraw accumulated fees from marketplace
     */
    function _withdraw(address erc20, uint256 amount, address payable receiver) internal nonReentrant {
        require(_feesCollected[erc20] >= amount, "Invalid amount");
        _feesCollected[erc20] -= amount;
        SettlementLib.sendTokens(erc20, address(this), receiver, amount);
        emit MarketplaceWithdraw(msg.sender, erc20, amount, receiver);
    }

    /**
     * @dev Withdraw escrow amounts
     */
    function _withdrawEscrow(address erc20, uint256 amount) internal nonReentrant {
        require(_escrow[msg.sender][erc20] >= amount, "Invalid amount");
        _escrow[msg.sender][erc20] -= amount;
        SettlementLib.sendTokens(erc20, address(this), payable(msg.sender), amount);
        emit MarketplaceWithdrawEscrow(msg.sender, erc20, amount);
    }

    function createListing(MarketplaceLib.ListingDetails calldata listingDetails, MarketplaceLib.TokenDetails calldata tokenDetails, MarketplaceLib.FeeData calldata feeData, MarketplaceLib.ListingReceiver[] calldata listingReceivers) external virtual override returns (uint256) {
        require(_enabled, "Disabled");
        require(_sellerRegistry == address(0) || IMarketplaceSellerRegistry(_sellerRegistry).isAuthorized(msg.sender), "Unauthorized");

        _listingCounter++;
        _listings[_listingCounter].id = _listingCounter;
        MarketplaceLib.constructListing(_listings[_listingCounter], _tokenReceiver, _feeBPS, listingDetails, tokenDetails, feeData, listingReceivers);

        return _listingCounter;
    }

    /**
     * @dev See {IMarketplace-purchase}.
     */
    function purchase(uint256 listingId) external payable virtual override nonReentrant {
        _purchase(payable(address(1)), msg.sender, listingId);
    }
    
    /**
     * @dev See {IMarketplace-purchase}.
     */
    function purchase(address referrer, uint256 listingId) external payable virtual override nonReentrant {
        _purchase(payable(referrer), msg.sender, listingId);
    }
    
    function _purchase(address payable referrer, address purchaser, uint256 listingId) private {
        MarketplaceLib.Listing storage listing = _listings[listingId];
        SettlementLib.performPurchase(_tokenReceiver, referrer, purchaser, listing, _feesCollected);
    }


    /**
     * @dev See {IMarketplace-bid}.
     */
    function bid(uint256 listingId, bool increase) external payable virtual override nonReentrant {
        _bid(msg.value, payable(address(1)), payable(msg.sender), listingId, increase);
    }

    /**
     * @dev See {IMarketplace-bid}.
     */
    function bid(address payable referrer, uint256 listingId, bool increase) external payable virtual override nonReentrant {
        _bid(msg.value, referrer, payable(msg.sender), listingId, increase);
    }

    /**
     * @dev See {IMarketplace-bid}.
     */
    function bid(uint256 listingId, uint256 bidAmount, bool increase) external virtual override nonReentrant {
        _bid(bidAmount, payable(address(1)), payable(msg.sender), listingId, increase);
    }

    /**
     * @dev See {IMarketplace-bid}.
     */
    function bid(address payable referrer, uint256 listingId, uint256 bidAmount, bool increase) external virtual override nonReentrant {
        _bid(bidAmount, referrer, payable(msg.sender), listingId, increase);
    }

    function _bid(uint256 bidAmount, address payable referrer, address payable bidder, uint256 listingId, bool increase) private {
        MarketplaceLib.Listing storage listing = _listings[listingId];
        BidTreeLib.BidTree storage bidTree = _listingBidTree[listingId];
        SettlementLib.performBid(bidAmount, referrer, bidder, listing, bidTree, increase, _escrow);
    }

    /**
     * @dev See {IMarketplace-collect}.
     */
    function collect(uint256 listingId) external virtual override nonReentrant {
        MarketplaceLib.Listing storage listing = _listings[listingId];

        require(listing.id > 0 && !listing.finalized, "Listing not found");
        require(listing.details.startTime != 0 && listing.details.endTime < block.timestamp, "Listing still active");
        require(msg.sender == listing.seller, "Only seller can collect");

        // Only tokens in custody and individual auction types allow funds collection pre-delivery
        require(!listing.token.lazy && listing.details.type_ == MarketplaceLib.ListingType.INDIVIDUAL_AUCTION, "Cannot collect");
        
        MarketplaceLib.Bid storage bid_ = listing.bid;
        require(!bid_.settled, "Already collected");
        
        // Settle bid
        SettlementLib.settleBid(bid_, listing, _feesCollected);
    }

    /**
     * Cancel an active sale and refund outstanding amounts
     */
    function _cancel(uint256 listingId, uint16 holdbackBPS) internal virtual nonReentrant {
        MarketplaceLib.Listing storage listing = _listings[listingId];
        require(listing.id > 0 && !listing.finalized, "Listing not found");
        require(holdbackBPS <= 10000, "Invalid input");

        // Immediately end and finalize
        listing.details.endTime = uint48(block.timestamp);
        listing.finalized = true;

        // Refund open bids
        if (listing.hasBid) {
            if (listing.details.type_ == MarketplaceLib.ListingType.INDIVIDUAL_AUCTION) {
                SettlementLib.refundBid(listing.bid, listing, holdbackBPS, _escrow);
            } else if (listing.details.type_ == MarketplaceLib.ListingType.RANKED_AUCTION) {
                BidTreeLib.BidTree storage bidTree = _listingBidTree[listing.id];
                address bidder = bidTree.first();
                while (bidder != address(0)) {
                    BidTreeLib.Bid storage bid_ = bidTree.getBid(bidder);
                    SettlementLib.refundBid(payable(bidder), bid_, listing, holdbackBPS, _escrow);
                    bidTree.next(bidder);
                }
            }
        }

        if (!listing.token.lazy) {
            // Return remaining items to seller
            SettlementLib.deliverToken(_tokenReceiver, listing, listing.seller, 0, true);
        }
        emit MarketplaceLib.CancelListing(listingId, msg.sender, holdbackBPS);
    }

    /**
     * @dev See {IMarketplace-finalize}.
     */
    function finalize(uint256 listingId) external payable virtual override nonReentrant {
        MarketplaceLib.Listing storage listing = _listings[listingId];
        require(listing.id > 0 && !listing.finalized, "Listing not found");
        require(listing.details.startTime != 0 && listing.details.endTime < block.timestamp, "Listing still active");

        if (!listing.hasBid) {
            if (!listing.token.lazy) {
                // No buyer, return to seller
                SettlementLib.deliverToken(_tokenReceiver, listing, listing.seller, 0, true);
            }
        } else if (listing.details.type_ == MarketplaceLib.ListingType.INDIVIDUAL_AUCTION) {
            MarketplaceLib.Bid storage currentBid = listing.bid;
            if (listing.token.lazy) {
                SettlementLib.deliverTokenLazy(listing, currentBid.bidder, currentBid.amount, 0);
            } else {
                SettlementLib.deliverToken(_tokenReceiver, listing, currentBid.bidder, currentBid.amount, false);
            }
            
            // Settle bid
            SettlementLib.settleBid(currentBid, listing, _feesCollected);
            // Mark delivered
            currentBid.delivered = true;

        } else if (listing.details.type_ == MarketplaceLib.ListingType.RANKED_AUCTION) {
            // Final sort order
            BidTreeLib.BidTree storage bidTree = _listingBidTree[listingId];
            address[] storage bidTreeFinalOrder = _listingBidTreeFinalOrder[listingId];
            address key = bidTree.first();
            while (key != address(0)) {
                bidTreeFinalOrder.push(key);
                key = bidTree.next(key);
            }
        } else {
            // Invalid type
            revert("Invalid type");
        }
        listing.finalized = true;

    }

    /**
     * @dev See {IMarketplace-deliver}.
     */
    function deliver(uint256 listingId, uint256 bidIndex) external payable override {
        MarketplaceLib.Listing storage listing = _listings[listingId];
        require(listing.id > 0 && listing.finalized, "Listing not found");
        require(listing.token.lazy && listing.details.type_ == MarketplaceLib.ListingType.RANKED_AUCTION, "Invalid listing type to deliver items");
        BidTreeLib.BidTree storage bidTree = _listingBidTree[listingId];

        require(bidIndex < bidTree.size, "Bid index out of range");
        address key = bidTree.first();
        uint256 keyIndex = 0;
        while (keyIndex < bidIndex) {
            key = bidTree.next(key);
            keyIndex++;
        }
        BidTreeLib.Bid storage bid_ = bidTree.getBid(key);
        require(!bid_.refunded, "Bid has been refunded");
        require(!bid_.delivered, "Bid already delivered");

        // Deliver item
        uint256 refundAmount = SettlementLib.deliverTokenLazy(listing, key, bid_.amount, bidIndex);
        require(refundAmount < bid_.amount, "Invalid delivery return value");

        // Refund bidder if necessary
        if (refundAmount > 0) {
            SettlementLib.refundTokens(listing.details.erc20, payable(key), refundAmount, _escrow);
        }
        // Settle bid
        SettlementLib.settleBid(bid_, listing, refundAmount, _feesCollected);
        // Mark delivered
        bid_.delivered = true;
    }

    /**
     * @dev See {IMarketplace-getListing}.
     */
    function getListing(uint256 listingId) external view override returns(MarketplaceLib.Listing memory) {
        require(listingId <= _listingCounter, "Invalid listing");
        return _listings[listingId];
    }

    /**
     * @dev See {IMarketplace-getListingCurrentPrice}.
     */
    function getListingCurrentPrice(uint256 listingId) external view override returns(uint256) {
        require(listingId <= _listingCounter, "Invalid listing");
        MarketplaceLib.Listing storage listing = _listings[listingId];
        require(listing.details.endTime > block.timestamp || listing.details.startTime == 0 || listing.finalized, "Listing is expired");
        return SettlementLib.computeListingPrice(listing, _listingBidTree[listingId]);
    }


    /**
     * @dev See {IMarketplace-geListingDeliverFee}.
     */
    function getListingDeliverFee(uint256 listingId, uint256 price) external view override returns(uint256) {
        require(listingId <= _listingCounter, "Invalid listing");
        MarketplaceLib.Listing storage listing = _listings[listingId];
        return SettlementLib.computeDeliverFee(listing, price);
    }

    /**
     * @dev See {IMarketplace-getBids}.
     */
    function getBids(uint256 listingId) external view virtual override returns(MarketplaceLib.Bid[] memory bids) {
        require(listingId <= _listingCounter, "Invalid listing");
        MarketplaceLib.Listing storage listing = _listings[listingId];
        if (listing.hasBid) {
            if (listing.details.type_ == MarketplaceLib.ListingType.RANKED_AUCTION) {
                BidTreeLib.BidTree storage bidTree = _listingBidTree[listingId];
                if (!listing.finalized) {
                    bids = new MarketplaceLib.Bid[](bidTree.size);
                    uint256 index = 0;
                    address key = bidTree.first();
                    while (key != address(0)) {
                        BidTreeLib.Bid storage bid_ = bidTree.getBid(key);
                        bids[index] = MarketplaceLib.Bid({amount:bid_.amount, bidder:payable(key), delivered:bid_.delivered, settled:bid_.settled, refunded:bid_.refunded, timestamp:bid_.timestamp, referrer:bid_.referrer});
                        key = bidTree.next(key);
                        index++;
                    }
                } else {
                    address[] storage bidTreeFinalOrder = _listingBidTreeFinalOrder[listingId];
                    bids = new MarketplaceLib.Bid[](bidTreeFinalOrder.length);
                    for (uint i = 0; i < bidTreeFinalOrder.length; i++) {
                        address key = bidTreeFinalOrder[i];
                        BidTreeLib.Bid storage bid_ = bidTree.getBid(key);
                        bids[i] = MarketplaceLib.Bid({amount:bid_.amount, bidder:payable(key), delivered:bid_.delivered, settled:bid_.settled, refunded:bid_.refunded, timestamp:bid_.timestamp, referrer:bid_.referrer});
                    }
                }
            } else {
                bids = new MarketplaceLib.Bid[](1);
                bids[0] = listing.bid;
            }
        }
        return bids;
    }

}