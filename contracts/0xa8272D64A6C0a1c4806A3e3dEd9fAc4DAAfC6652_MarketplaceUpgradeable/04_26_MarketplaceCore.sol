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

abstract contract MarketplaceCore is IMarketplaceCore, IERC721Receiver {
    using EnumerableSet for EnumerableSet.AddressSet;

    bool private _enabled;
    address private _sellerRegistry;
     
    uint40 private _listingCounter;
    mapping (uint40 => MarketplaceLib.Listing) private _listings;
    mapping (uint40 => mapping (address => MarketplaceLib.Offer)) private _listingOffers;
    mapping (uint40 => EnumerableSet.AddressSet) private _listingOfferAddresses;
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
            bool acceptOffers,
            bytes memory listingData
        ) = abi.decode(data, (MarketplaceLib.ListingDetails, MarketplaceLib.TokenDetails, MarketplaceLib.DeliveryFees, MarketplaceLib.ListingReceiver[], bool, bool, bytes));
        require(msg.sender == tokenDetails.address_ && tokenId == tokenDetails.id && tokenDetails.spec == TokenLib.Spec.ERC721, "Invalid config");
        _createListing(from, listingDetails, tokenDetails, deliveryFees, listingReceivers, enableReferrer, acceptOffers, listingData, false);
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
                bool acceptOffers,
                bytes memory listingData
            ) = abi.decode(data, (MarketplaceLib.ListingDetails, MarketplaceLib.TokenDetails, MarketplaceLib.DeliveryFees, MarketplaceLib.ListingReceiver[], bool, bool, bytes));
            require(msg.sender == tokenDetails.address_ && tokenId == tokenDetails.id && tokenDetails.spec == TokenLib.Spec.ERC1155 && count == listingDetails.totalAvailable, "Invalid config");
            _createListing(from, listingDetails, tokenDetails, deliveryFees, listingReceivers, enableReferrer, acceptOffers, listingData, false);
        }
        return this.onERC1155Received.selector;
    }

    /**
     * @dev See {IMarketplaceCore-createListing}.
     */
    function createListing(MarketplaceLib.ListingDetails calldata listingDetails, MarketplaceLib.TokenDetails calldata tokenDetails, MarketplaceLib.DeliveryFees calldata deliveryFees, MarketplaceLib.ListingReceiver[] calldata listingReceivers, bool enableReferrer, bool acceptOffers, bytes calldata data) external virtual override returns (uint40) {
        return _createListing(msg.sender, listingDetails, tokenDetails, deliveryFees, listingReceivers, enableReferrer, acceptOffers, data, true);
    }

    function _createListing(address seller, MarketplaceLib.ListingDetails memory listingDetails, MarketplaceLib.TokenDetails memory tokenDetails, MarketplaceLib.DeliveryFees memory deliveryFees, MarketplaceLib.ListingReceiver[] memory listingReceivers, bool enableReferrer, bool acceptOffers, bytes memory data, bool intake) private returns (uint40) {
        require(_enabled, "Disabled");
        require(_sellerRegistry == address(0) || IMarketplaceSellerRegistry(_sellerRegistry).isAuthorized(seller, data), "Unauthorized");

        _listingCounter++;
        MarketplaceLib.Listing storage listing = _listings[_listingCounter];
        listing.marketplaceBPS = feeBPS;
        if (enableReferrer) {
            listing.referrerBPS = referrerBPS;
        }
        MarketplaceLib.constructListing(seller, _listingCounter, listing, listingDetails, tokenDetails, deliveryFees, listingReceivers, acceptOffers, intake);

        return _listingCounter;
    }

    /**
     * @dev See {IMarketplaceCore-modifyListing}.
     */
    function modifyListing(uint40 listingId, uint256 initialAmount, uint48 startTime, uint48 endTime) external virtual override {
        MarketplaceLib.Listing storage listing = _getListing(listingId);
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
        MarketplaceLib.Listing storage listing = _getListing(listingId);
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
        MarketplaceLib.Listing storage listing = _getListing(listingId);
        SettlementLib.performBid(listingId, listing, bidAmount, referrer, increase, _escrow, data);
    }

    /**
     * @dev See {IMarketplaceCore-offer}.
     */
    function offer(uint40 listingId, bool increase) external payable virtual override {
        _offer(msg.value, payable(address(0)), listingId, increase, "");
    }
    function offer(uint40 listingId, bool increase, bytes calldata data) external payable virtual override {
        _offer(msg.value, payable(address(0)), listingId, increase, data);
    }

    /**
     * @dev See {IMarketplaceCore-offer}.
     */
    function offer(address payable referrer, uint40 listingId, bool increase) external payable virtual override {
        _offer(msg.value, referrer, listingId, increase, "");
    }
    function offer(address payable referrer, uint40 listingId, bool increase, bytes calldata data) external payable virtual override {
        _offer(msg.value, referrer, listingId, increase, data);
    }

    /**
     * @dev See {IMarketplaceCore-offer}.
     */
    function offer(uint40 listingId, uint256 offerAmount, bool increase) external virtual override {
        _offer(offerAmount, payable(address(0)), listingId, increase, "");
    }
    function offer(uint40 listingId, uint256 offerAmount, bool increase, bytes calldata data) external virtual override {
        _offer(offerAmount, payable(address(0)), listingId, increase, data);
    }

    /**
     * @dev See {IMarketplaceCore-offer}.
     */
    function offer(address payable referrer, uint40 listingId, uint256 offerAmount, bool increase) external virtual override {
        _offer(offerAmount, referrer, listingId, increase, "");
    }
    function offer(address payable referrer, uint40 listingId, uint256 offerAmount, bool increase, bytes calldata data) external virtual override {
        _offer(offerAmount, referrer, listingId, increase, data);
    }

    function _offer(uint256 offerAmount, address payable referrer, uint40 listingId, bool increase, bytes memory data) private {
        MarketplaceLib.Listing storage listing = _getListing(listingId);
        SettlementLib.makeOffer(listingId, listing, offerAmount, referrer, _listingOffers[listingId], _listingOfferAddresses[listingId], increase, data);
    }

    /**
     * @dev See {IMarketplaceCore-rescind}.
     */
    function rescind(uint40 listingId) public virtual override {
        MarketplaceLib.Listing storage listing = _getListing(listingId);
        MarketplaceLib.ListingType listingType = listing.details.type_;

        // Can only rescind offers if
        // 1. Listing is NOT an OFFERS_ONLY type
        // 2. Listing has been finalized
        // 3. Listing IS an OFFERS_ONLY type that has ended over 24 hours ago
        // it has been finalized, or it has been 24 hours after the listing end time
        require(
            listingType != MarketplaceLib.ListingType.OFFERS_ONLY ||
            MarketplaceLib.isFinalized(listing.flags) ||
            (listing.details.endTime+86400) < block.timestamp,
            "Cannot be rescinded yet"
        );
        SettlementLib.rescindOffer(listingId, listing, msg.sender, _listingOffers[listingId], _listingOfferAddresses[listingId]);
    }
    function rescind(uint40[] calldata listingIds) external virtual override {
        for (uint i; i < listingIds.length;) {
            rescind(listingIds[i]);
            unchecked { ++i; }
        }
    }
    function rescind(uint40 listingId, address[] calldata offerAddresses) external virtual override {
        MarketplaceLib.Listing storage listing = _getListing(listingId);
        require(listing.seller == msg.sender, "Permission denied");
        for (uint i; i < offerAddresses.length;) {
            SettlementLib.rescindOffer(listingId, listing, offerAddresses[i], _listingOffers[listingId], _listingOfferAddresses[listingId]);
            unchecked { ++i; }
        }
    }

    /**
     * @dev See {IMarketplaceCore-accept}.
     */
    function accept(uint40 listingId, address[] calldata addresses, uint256[] calldata amounts, uint256 maxAmount) external virtual override {
        uint256 addressLength = addresses.length;
        require(addressLength == amounts.length, "Invalid input");
        MarketplaceLib.Listing storage listing = _getListing(listingId);
        MarketplaceLib.ListingType listingType = listing.details.type_;
        require(msg.sender == listing.seller && !MarketplaceLib.isFinalized(listing.flags), "Invalid listing");

        // Mark as finalized first to prevent re-entrancy
        listing.flags |= MarketplaceLib.FLAG_MASK_FINALIZED;
        // End the listing
        if (listing.details.startTime == 0) listing.details.startTime = uint48(block.timestamp);
        if (listing.details.endTime > block.timestamp) listing.details.endTime = uint48(block.timestamp);
        uint24 totalPerSale = listing.details.totalPerSale;

        if (MarketplaceLib.isAuction(listingType)) {
            require(!MarketplaceLib.hasBid(listing.flags), "Cannot accept offers when bid has been made");
            require(addressLength == 1, "Too many offers accepted");
            listing.totalSold += totalPerSale;
            _accept(listingId, listing, payable(addresses[0]), amounts[0], maxAmount, 0);
        } else if (MarketplaceLib.isOffer(listingType)) {
            require(addressLength*totalPerSale <= listing.details.totalAvailable, "Too many offers accepted");
            listing.totalSold += uint24(totalPerSale*addressLength);
            for (uint i; i < addressLength;) {
                _accept(listingId, listing, payable(addresses[i]), amounts[i], maxAmount, i);
                unchecked { ++i; }
            }
        }
    }

    function _accept(uint40 listingId, MarketplaceLib.Listing storage listing, address payable offerAddress, uint256 expectedAmount, uint256 maxAmount, uint256 index) private {
        require(_listingOfferAddresses[listingId].contains(offerAddress), "Invalid address");
        MarketplaceLib.Offer storage currentOffer = _listingOffers[listingId][offerAddress];
        require(currentOffer.amount == expectedAmount, "Invalid state");
        if (listing.token.lazy) {
            SettlementLib.deliverTokenLazy(listingId, listing, offerAddress, 1, expectedAmount, index);
        } else {
            SettlementLib.deliverToken(listing, offerAddress, 1, expectedAmount, false);
        }
        // Settle offer
        SettlementLib.settleOffer(_royaltyEngineV1, listingId, listing, currentOffer, offerAddress, _feesCollected, maxAmount, _escrow);
    }

    /**
     * @dev See {IMarketplaceCore-collect}.
     */
    function collect(uint40 listingId) external virtual override {
        MarketplaceLib.Listing storage listing = _getListing(listingId);
        require(msg.sender == listing.seller && !MarketplaceLib.isFinalized(listing.flags), "Invalid listing");
        require(listing.details.startTime != 0 && listing.details.endTime < block.timestamp, "Invalid state");

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
        MarketplaceLib.Listing storage listing = _getListing(listingId);
        require(!MarketplaceLib.isFinalized(listing.flags), "Invalid listing");
        require(holdbackBPS <= 1000, "Invalid input");

        if (!isAdmin) {
           // If not admin, must be seller, must not have holdbackBPS, auction cannot have started
           require(listing.seller == msg.sender, "Permission denied");
           require(holdbackBPS == 0, "Invalid input");
           require(!MarketplaceLib.hasBid(listing.flags), "Invalid state");
        }
        
        // Immediately end and finalize to prevent re-entrancy
        if (listing.details.startTime == 0) listing.details.startTime = uint48(block.timestamp);
        listing.details.endTime = uint48(block.timestamp);
        listing.flags |= MarketplaceLib.FLAG_MASK_FINALIZED;

        // Refund open bids
        if (MarketplaceLib.hasBid(listing.flags)) {
            if (listing.details.type_ == MarketplaceLib.ListingType.INDIVIDUAL_AUCTION) {
                SettlementLib.refundBid(listing.bid, listing, holdbackBPS, _escrow);
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
        MarketplaceLib.Listing storage listing = _getListing(listingId);
        MarketplaceLib.ListingType listingType = listing.details.type_;
        require(!MarketplaceLib.isOffer(listingType), "Invalid type");
        require(!MarketplaceLib.isFinalized(listing.flags), "Invalid listing");
        require(listing.details.startTime != 0 && listing.details.endTime < block.timestamp, "Invalid state");

        // Mark as finalized first to prevent re-entrancy
        listing.flags |= MarketplaceLib.FLAG_MASK_FINALIZED;

        if (!MarketplaceLib.hasBid(listing.flags)) {
            if (!listing.token.lazy) {
                // No buyer, return to seller
                SettlementLib.deliverToken(listing, listing.seller, 1, 0, true);
            }
        } else if (listingType == MarketplaceLib.ListingType.INDIVIDUAL_AUCTION) {
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

        } else {
            // Invalid type
            revert("Invalid type");
        }

        emit MarketplaceLib.FinalizeListing(listingId);
    }

    /**
     * @dev See {IMarketplaceCore-getListing}.
     */
    function getListing(uint40 listingId) external view override returns(Listing memory listing) {
        MarketplaceLib.Listing storage internalListing = _getListing(listingId);
        listing.id = listingId;
        listing.seller = internalListing.seller;
        listing.finalized = MarketplaceLib.isFinalized(internalListing.flags);
        listing.totalSold = internalListing.totalSold;
        listing.marketplaceBPS = internalListing.marketplaceBPS;
        listing.referrerBPS = internalListing.referrerBPS;
        listing.details = internalListing.details;
        listing.token = internalListing.token;
        listing.receivers = internalListing.receivers;
        listing.fees = internalListing.fees;
        listing.bid = internalListing.bid;
        listing.offersAccepted = (internalListing.flags & MarketplaceLib.FLAG_MASK_ACCEPT_OFFERS) != 0;
    }

    /**
     * @dev See {IMarketplaceCore-getListingCurrentPrice}.
     */
    function getListingCurrentPrice(uint40 listingId) external view override returns(uint256) {
        MarketplaceLib.Listing storage listing = _getListing(listingId);
        return SettlementLib.computeListingPrice(listing);
    }

    /**
     * @dev See {IMarketplaceCore-getListingTotalPrice}.
     */
    function getListingTotalPrice(uint40 listingId, uint24 count) external view override returns(uint256) {
        MarketplaceLib.Listing storage listing = _getListing(listingId);
        return SettlementLib.computeTotalPrice(listing, count);
    }

    /**
     * @dev See {IMarketplaceCore-geListingDeliverFee}.
     */
    function getListingDeliverFee(uint40 listingId, uint256 price) external view override returns(uint256) {
        MarketplaceLib.Listing storage listing = _getListing(listingId);
        return SettlementLib.computeDeliverFee(listing, price);
    }

    /**
     * @dev See {IMarketplaceCore-getBids}.
     */
    function getBids(uint40 listingId) external view virtual override returns(MarketplaceLib.Bid[] memory bids) {
        MarketplaceLib.Listing storage listing = _getListing(listingId);
        if (MarketplaceLib.hasBid(listing.flags)) {
            bids = new MarketplaceLib.Bid[](1);
            bids[0] = listing.bid;
        }
    }

    /**
     * @dev See {IMarketplaceCore-getOffers}
     */
    function getOffers(uint40 listingId) external view override returns(Offer[] memory offers) {
        EnumerableSet.AddressSet storage offerAddresses = _listingOfferAddresses[listingId];
        uint256 offerCount = offerAddresses.length();
        offers = new Offer[](offerCount);
        for (uint i; i < offerCount;) {
            address offerer = offerAddresses.at(i);
            MarketplaceLib.Offer memory internalOffer = _listingOffers[listingId][offerer];
            offers[i].offerer = offerer;
            offers[i].amount = internalOffer.amount;
            offers[i].timestamp = internalOffer.timestamp;
            offers[i].accepted = internalOffer.accepted;
            unchecked { i++; }
        }
    }

    function _getListing(uint40 listingId) private view returns(MarketplaceLib.Listing storage) {
        require(listingId > 0 && listingId <= _listingCounter, "Invalid listing");
        return _listings[listingId];
    }

}