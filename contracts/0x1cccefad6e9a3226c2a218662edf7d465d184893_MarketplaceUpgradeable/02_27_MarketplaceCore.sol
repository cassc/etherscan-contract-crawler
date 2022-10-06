// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./IMarketplaceCore.sol";
import "./IMarketplaceSellerRegistry.sol";

import "./libs/MarketplaceLib.sol";
import "./libs/SettlementLib.sol";
import "./libs/TokenLib.sol";
import "./libs/BidTreeLib.sol";

abstract contract MarketplaceCore is IMarketplaceCore, IERC721Receiver {
    using EnumerableSet for EnumerableSet.AddressSet;
    using BidTreeLib for BidTreeLib.BidTree;

    bool private _enabled;
    address private _sellerRegistry;
     
    uint40 private _listingCounter;
    mapping (uint40 => MarketplaceLib.Listing) private _listings;
    mapping (uint40 => BidTreeLib.BidTree) private _listingBidTree;
    mapping (uint40 => address[]) private _listingBidTreeFinalOrder;
    mapping (address => mapping (address => uint256)) private _escrow;

    // Marketplace fee
    uint16 public feeBPS;
    uint16 public referrerBPS;
    mapping (address => uint256) _feesCollected;

    // Royalty Engine
    address private _royaltyEngineV1;

    uint256[50] private __gap;

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
        require(ERC165Checker.supportsInterface(registry, type(IMarketplaceSellerRegistry).interfaceId), "Invalid input");
        _sellerRegistry = registry;
        emit MarketplaceSellerRegistry(msg.sender, registry);
    }

    /**
     * @dev Set royalty engine
     */
    function _setRoyaltyEngineV1(address royaltyEngineV1) internal {
        require(_royaltyEngineV1 == address(0), "Invalid state");
        emit MarketplaceRoyaltyEngineUpdate(royaltyEngineV1);
        _royaltyEngineV1 = royaltyEngineV1;
    }

    /**
     * @dev Set marketplace fees
     */
    function _setFees(uint16 feeBPS_, uint16 referrerBPS_) internal {
        require(feeBPS_ <= 1500 && referrerBPS_ <= 1500, "Invalid config");
        feeBPS = feeBPS_;
        referrerBPS = referrerBPS_;
        emit MarketplaceFees(msg.sender, feeBPS, referrerBPS);
    }

    /**
     * @dev Withdraw accumulated fees from marketplace
     */
    function _withdraw(address erc20, uint256 amount, address payable receiver) internal {
        require(_feesCollected[erc20] >= amount, "Invalid amount");
        _feesCollected[erc20] -= amount;
        SettlementLib.sendTokens(erc20, address(this), receiver, amount);
        emit MarketplaceWithdraw(msg.sender, erc20, amount, receiver);
    }

    /**
     * @dev Withdraw escrow amounts
     */
    function _withdrawEscrow(address erc20, uint256 amount) internal {
        require(_escrow[msg.sender][erc20] >= amount, "Invalid amount");
        _escrow[msg.sender][erc20] -= amount;
        SettlementLib.sendTokens(erc20, address(this), payable(msg.sender), amount);
        emit MarketplaceWithdrawEscrow(msg.sender, erc20, amount);
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
        require(operator == from, "Unauthorized");
        (
            MarketplaceLib.ListingDetails memory listingDetails,
            MarketplaceLib.TokenDetails memory tokenDetails,
            MarketplaceLib.DeliveryFees memory deliveryFees,
            MarketplaceLib.ListingReceiver[] memory listingReceivers,
            bool enableReferrer,
            bytes memory listingData
        ) = abi.decode(data, (MarketplaceLib.ListingDetails, MarketplaceLib.TokenDetails, MarketplaceLib.DeliveryFees, MarketplaceLib.ListingReceiver[], bool, bytes));
        require(msg.sender == tokenDetails.address_ && tokenId == tokenDetails.id && tokenDetails.spec == TokenLib.Spec.ERC721, "Invalid config");
        _createListing(from, listingDetails, tokenDetails, deliveryFees, listingReceivers, enableReferrer, listingData, false);
        return this.onERC721Received.selector;
    }

    /**
     * @dev See {IERC721Receiver-onERC1155Received}.
     */
    function onERC1155Received(address operator, address from, uint256 tokenId, uint256 count, bytes calldata data) external virtual returns(bytes4) {
        if (operator != address(this)) {
            require(operator == from, "Unauthorized");
            (
                MarketplaceLib.ListingDetails memory listingDetails,
                MarketplaceLib.TokenDetails memory tokenDetails,
                MarketplaceLib.DeliveryFees memory deliveryFees,
                MarketplaceLib.ListingReceiver[] memory listingReceivers,
                bool enableReferrer,
                bytes memory listingData
            ) = abi.decode(data, (MarketplaceLib.ListingDetails, MarketplaceLib.TokenDetails, MarketplaceLib.DeliveryFees, MarketplaceLib.ListingReceiver[], bool, bytes));
            require(msg.sender == tokenDetails.address_ && tokenId == tokenDetails.id && tokenDetails.spec == TokenLib.Spec.ERC1155 && count == listingDetails.totalAvailable, "Invalid config");
            _createListing(from, listingDetails, tokenDetails, deliveryFees, listingReceivers, enableReferrer, listingData, false);
        }
        return this.onERC1155Received.selector;
    }

    /**
     * @dev See {IMarketplaceCore-createListing}.
     */
    function createListing(MarketplaceLib.ListingDetails calldata listingDetails, MarketplaceLib.TokenDetails calldata tokenDetails, MarketplaceLib.DeliveryFees calldata deliveryFees, MarketplaceLib.ListingReceiver[] calldata listingReceivers, bool enableReferrer, bytes calldata data) external virtual override returns (uint256) {
        return _createListing(msg.sender, listingDetails, tokenDetails, deliveryFees, listingReceivers, enableReferrer, data, true);
    }

    function _createListing(address seller, MarketplaceLib.ListingDetails memory listingDetails, MarketplaceLib.TokenDetails memory tokenDetails, MarketplaceLib.DeliveryFees memory deliveryFees, MarketplaceLib.ListingReceiver[] memory listingReceivers, bool enableReferrer, bytes memory data, bool intake) private returns (uint256) {
        require(_enabled, "Disabled");
        require(_sellerRegistry == address(0) || IMarketplaceSellerRegistry(_sellerRegistry).isAuthorized(seller, data), "Unauthorized");

        _listingCounter++;
        MarketplaceLib.Listing storage listing = _listings[_listingCounter];
        listing.marketplaceBPS = feeBPS;
        if (enableReferrer) {
            listing.referrerBPS = referrerBPS;
        }
        MarketplaceLib.constructListing(seller, _listingCounter, listing, listingDetails, tokenDetails, deliveryFees, listingReceivers, intake);

        return _listingCounter;
    }

    /**
     * @dev See {IMarketplaceCore-modifyListing}.
     */
    function modifyListing(uint40 listingId, uint256 initialAmount, uint48 startTime, uint48 endTime) external virtual override {
        require(listingId <= _listingCounter, "Invalid listing");
        MarketplaceLib.Listing storage listing = _listings[listingId];
        MarketplaceLib.modifyListing(listingId, listing, initialAmount, startTime, endTime);
    }

    /**
     * @dev See {IMarketplaceCore-purchase}.
     */
    function purchase(uint40 listingId) external payable virtual override {
        _purchase(payable(address(0)), listingId, 1, "");
    }
    function purchase(uint40 listingId, bytes calldata data) external payable virtual override {
        _purchase(payable(address(0)), listingId, 1, data);
    }
    
    /**
     * @dev See {IMarketplaceCore-purchase}.
     */
    function purchase(address referrer, uint40 listingId) external payable virtual override {
        _purchase(payable(referrer), listingId, 1, "");
    }
    function purchase(address referrer, uint40 listingId, bytes calldata data) external payable virtual override {
        _purchase(payable(referrer), listingId, 1, data);
    }

    /**
     * @dev See {IMarketplaceCore-purchase}.
     */  
    function purchase(uint40 listingId, uint24 count) external payable virtual override {
        _purchase(payable(address(0)), listingId, count, "");
    }
    function purchase(uint40 listingId, uint24 count, bytes calldata data) external payable virtual override {
        _purchase(payable(address(0)), listingId, count, data);
    }
  
    /**
     * @dev See {IMarketplaceCore-purchase}.
     */
    function purchase(address referrer, uint40 listingId, uint24 count) external payable virtual override {
        _purchase(payable(referrer), listingId, count, "");
    }
    function purchase(address referrer, uint40 listingId, uint24 count, bytes calldata data) external payable virtual override {
        _purchase(payable(referrer), listingId, count, data);
    }
    
    function _purchase(address payable referrer, uint40 listingId, uint24 count, bytes memory data) private {
        require(listingId > 0 && listingId <= _listingCounter, "Invalid listing");
        MarketplaceLib.Listing storage listing = _listings[listingId];
        SettlementLib.performPurchase(_royaltyEngineV1, referrer, listingId, listing, count, _feesCollected, data);
    }

    /**
     * @dev See {IMarketplaceCore-bid}.
     */
    function bid(uint40 listingId, bool increase) external payable virtual override {
        _bid(msg.value, payable(address(0)), listingId, increase, "");
    }
    function bid(uint40 listingId, bool increase, bytes calldata data) external payable virtual override {
        _bid(msg.value, payable(address(0)), listingId, increase, data);
    }

    /**
     * @dev See {IMarketplaceCore-bid}.
     */
    function bid(address payable referrer, uint40 listingId, bool increase) external payable virtual override {
        _bid(msg.value, referrer, listingId, increase, "");
    }
    function bid(address payable referrer, uint40 listingId, bool increase, bytes calldata data) external payable virtual override {
        _bid(msg.value, referrer, listingId, increase, data);
    }

    /**
     * @dev See {IMarketplaceCore-bid}.
     */
    function bid(uint40 listingId, uint256 bidAmount, bool increase) external virtual override {
        _bid(bidAmount, payable(address(0)), listingId, increase, "");
    }
    function bid(uint40 listingId, uint256 bidAmount, bool increase, bytes calldata data) external virtual override {
        _bid(bidAmount, payable(address(0)), listingId, increase, data);
    }

    /**
     * @dev See {IMarketplaceCore-bid}.
     */
    function bid(address payable referrer, uint40 listingId, uint256 bidAmount, bool increase) external virtual override {
        _bid(bidAmount, referrer, listingId, increase, "");
    }
    function bid(address payable referrer, uint40 listingId, uint256 bidAmount, bool increase, bytes calldata data) external virtual override {
        _bid(bidAmount, referrer, listingId, increase, data);
    }

    function _bid(uint256 bidAmount, address payable referrer, uint40 listingId, bool increase, bytes memory data) private {
        require(listingId > 0 && listingId <= _listingCounter, "Invalid listing");
        MarketplaceLib.Listing storage listing = _listings[listingId];
        MarketplaceLib.ListingType listingType = listing.details.type_;

        if (listingType == MarketplaceLib.ListingType.INDIVIDUAL_AUCTION) {
             SettlementLib.performBidIndividual(listingId, listing, bidAmount, referrer, increase, _escrow, data);
        } else if (listingType == MarketplaceLib.ListingType.RANKED_AUCTION) {
            BidTreeLib.BidTree storage bidTree = _listingBidTree[listingId];
            SettlementLib.performBidRanked(listingId, listing, bidTree, bidAmount, increase, _escrow, data);
        } else {
            revert("Invalid listing");
        }
    }

    /**
     * @dev See {IMarketplaceCore-collect}.
     */
    function collect(uint40 listingId) external virtual override {
        require(listingId > 0 && listingId <= _listingCounter, "Invalid listing");
        MarketplaceLib.Listing storage listing = _listings[listingId];
        require((listing.flags & MarketplaceLib.FLAG_MASK_FINALIZED) == 0, "Invalid listing");
        require(listing.details.startTime != 0 && listing.details.endTime < block.timestamp, "Invalid state");
        require(msg.sender == listing.seller, "Permission denied");

        // Only tokens in custody and individual auction types allow funds collection pre-delivery
        require(!listing.token.lazy && listing.details.type_ == MarketplaceLib.ListingType.INDIVIDUAL_AUCTION, "Invalid type");
        
        MarketplaceLib.Bid storage bid_ = listing.bid;
        require(!bid_.settled, "Invalid state");
        
        // Settle bid
        SettlementLib.settleBid(_royaltyEngineV1, bid_, listing, _feesCollected);
    }

    /**
     * Cancel an active sale and refund outstanding amounts
     */
    function _cancel(uint40 listingId, uint16 holdbackBPS, bool isAdmin) internal virtual {
        require(listingId > 0 && listingId <= _listingCounter, "Invalid listing");
        MarketplaceLib.Listing storage listing = _listings[listingId];
        require((listing.flags & MarketplaceLib.FLAG_MASK_FINALIZED) == 0, "Invalid listing");
        require(holdbackBPS <= 1000, "Invalid input");

        if (!isAdmin) {
           // If not admin, must be seller, must not have holdbackBPS, auction cannot have started
           require(listing.seller == msg.sender, "Permission denied");
           require(holdbackBPS == 0, "Invalid input");
           require((listing.flags & MarketplaceLib.FLAG_MASK_HAS_BID) == 0, "Invalid state");
        }
        
        // Immediately end and finalize
        if (listing.details.startTime == 0) listing.details.startTime = uint48(block.timestamp);
        listing.details.endTime = uint48(block.timestamp);
        listing.flags |= MarketplaceLib.FLAG_MASK_FINALIZED;

        // Refund open bids
        if ((listing.flags & MarketplaceLib.FLAG_MASK_HAS_BID) != 0) {
            if (listing.details.type_ == MarketplaceLib.ListingType.INDIVIDUAL_AUCTION) {
                SettlementLib.refundBid(listing.bid, listing, holdbackBPS, _escrow);
            } else if (listing.details.type_ == MarketplaceLib.ListingType.RANKED_AUCTION) {
                BidTreeLib.BidTree storage bidTree = _listingBidTree[listingId];
                address bidder = bidTree.first();
                while (bidder != address(0)) {
                    BidTreeLib.Bid storage bid_ = bidTree.getBid(bidder);
                    SettlementLib.refundBid(payable(bidder), bid_, listing, holdbackBPS, _escrow);
                    bidder = bidTree.next(bidder);
                }
            }
        }

        if (!listing.token.lazy) {
            // Return remaining items to seller
            SettlementLib.deliverToken(listing, listing.seller, 1, 0, true);
        }
        emit MarketplaceLib.CancelListing(listingId, msg.sender, holdbackBPS);
    }

    /**
     * @dev See {IMarketplaceCore-finalize}.
     */
    function finalize(uint40 listingId) external payable virtual override {
        require(listingId > 0 && listingId <= _listingCounter, "Invalid listing");
        MarketplaceLib.Listing storage listing = _listings[listingId];
        require((listing.flags & MarketplaceLib.FLAG_MASK_FINALIZED) == 0, "Invalid listing");
        require(listing.details.startTime != 0 && listing.details.endTime < block.timestamp, "Invalid state");

        // Mark as finalized first to prevent re-entrancy
        listing.flags |= MarketplaceLib.FLAG_MASK_FINALIZED;

        if ((listing.flags & MarketplaceLib.FLAG_MASK_HAS_BID) == 0) {
            if (!listing.token.lazy) {
                // No buyer, return to seller
                SettlementLib.deliverToken(listing, listing.seller, 1, 0, true);
            }
        } else if (listing.details.type_ == MarketplaceLib.ListingType.INDIVIDUAL_AUCTION) {
            listing.totalSold += listing.details.totalPerSale;
            MarketplaceLib.Bid storage currentBid = listing.bid;
            if (listing.token.lazy) {
                SettlementLib.deliverTokenLazy(listingId, listing, currentBid.bidder, 1, currentBid.amount, 0);
            } else {
                SettlementLib.deliverToken(listing, currentBid.bidder, 1, currentBid.amount, false);
            }
            
            // Settle bid
            SettlementLib.settleBid(_royaltyEngineV1, currentBid, listing, _feesCollected);
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
           listing.totalSold += uint24(bidTreeFinalOrder.length*listing.details.totalPerSale);
        } else {
            // Invalid type
            revert("Invalid type");
        }
    }

    /**
     * @dev See {IMarketplace-deliver}.
     */
    function deliver(uint40 listingId, uint256 bidIndex) external payable override {
        require(listingId > 0 && listingId <= _listingCounter, "Invalid listing");
        MarketplaceLib.Listing storage listing = _listings[listingId];
        require((listing.flags & MarketplaceLib.FLAG_MASK_FINALIZED) != 0, "Invalid listing");
        require(listing.token.lazy && listing.details.type_ == MarketplaceLib.ListingType.RANKED_AUCTION, "Invalid type");

        BidTreeLib.BidTree storage bidTree = _listingBidTree[listingId];

        require(bidIndex < bidTree.size, "Out of range");
        address key = bidTree.first();
        uint256 keyIndex = 0;
        while (keyIndex < bidIndex) {
            key = bidTree.next(key);
            keyIndex++;
        }
        BidTreeLib.Bid storage bid_ = bidTree.getBid(key);
        require(!bid_.refunded && !bid_.delivered, "Invalid state");

        // Mark delivered first to prevent re-entrancy
        bid_.delivered = true;

        // Deliver item
        uint256 refundAmount = SettlementLib.deliverTokenLazy(listingId, listing, key, 1, bid_.amount, bidIndex);
        require(refundAmount < bid_.amount, "Invalid input");

        // Refund bidder if necessary
        if (refundAmount > 0) {
            SettlementLib.refundTokens(listing.details.erc20, payable(key), refundAmount, _escrow);
        }
        // Settle bid
        SettlementLib.settleBid(_royaltyEngineV1, bid_, listing, refundAmount, _feesCollected);
    }

    /**
     * @dev See {IMarketplaceCore-getListing}.
     */
    function getListing(uint40 listingId) external view override returns(Listing memory listing) {
        require(listingId > 0 && listingId <= _listingCounter, "Invalid listing");
        MarketplaceLib.Listing memory internalListing = _listings[listingId];
        listing.id = listingId;
        listing.seller = internalListing.seller;
        listing.finalized = (internalListing.flags & MarketplaceLib.FLAG_MASK_FINALIZED) != 0;
        listing.totalSold = internalListing.totalSold;
        listing.marketplaceBPS = internalListing.marketplaceBPS;
        listing.referrerBPS = internalListing.referrerBPS;
        listing.details = internalListing.details;
        listing.token = internalListing.token;
        listing.receivers = internalListing.receivers;
        listing.fees = internalListing.fees;
        listing.bid = internalListing.bid;
    }

    /**
     * @dev See {IMarketplaceCore-getListingCurrentPrice}.
     */
    function getListingCurrentPrice(uint40 listingId) external view override returns(uint256) {
        require(listingId > 0 && listingId <= _listingCounter, "Invalid listing");
        MarketplaceLib.Listing storage listing = _listings[listingId];
        return SettlementLib.computeListingPrice(listing, _listingBidTree[listingId]);
    }

    /**
     * @dev See {IMarketplaceCore-getListingTotalPrice}.
     */
    function getListingTotalPrice(uint40 listingId, uint24 count) external view override returns(uint256) {
        require(listingId > 0 && listingId <= _listingCounter, "Invalid listing");
        MarketplaceLib.Listing storage listing = _listings[listingId];
        return SettlementLib.computeTotalPrice(listing, count);
    }

    /**
     * @dev See {IMarketplaceCore-geListingDeliverFee}.
     */
    function getListingDeliverFee(uint40 listingId, uint256 price) external view override returns(uint256) {
        require(listingId > 0 && listingId <= _listingCounter, "Invalid listing");
        MarketplaceLib.Listing storage listing = _listings[listingId];
        return SettlementLib.computeDeliverFee(listing, price);
    }

    /**
     * @dev See {IMarketplaceCore-getBids}.
     */
    function getBids(uint40 listingId) external view virtual override returns(MarketplaceLib.Bid[] memory bids) {
        require(listingId > 0 && listingId <= _listingCounter, "Invalid listing");
        MarketplaceLib.Listing storage listing = _listings[listingId];
        return MarketplaceLib.getBids(listingId, listing, _listingBidTree, _listingBidTreeFinalOrder);
    }

}