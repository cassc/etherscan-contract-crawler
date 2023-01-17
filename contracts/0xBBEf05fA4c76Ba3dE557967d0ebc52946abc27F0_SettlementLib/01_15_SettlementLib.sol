// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@manifoldxyz/royalty-registry-solidity/contracts/IRoyaltyEngineV1.sol";

import "../IIdentityVerifier.sol";
import "../ILazyDelivery.sol";
import "../IPriceEngine.sol";

import "./MarketplaceLib.sol";
import "./TokenLib.sol";

/**
 * @dev Marketplace settlement logic
 */
library SettlementLib {
    using EnumerableSet for EnumerableSet.AddressSet;

    event Escrow(address indexed receiver, address erc20, uint256 amount);

    /**
     * Purchase logic
     */
    function performPurchase(address royaltyEngineV1, address payable referrer, uint40 listingId, MarketplaceLib.Listing storage listing, uint24 count, mapping(address => uint256) storage feesCollected, bytes memory data) public {
        require(MarketplaceLib.isPurchase(listing.details.type_), "Not available to purchase");
        require(listing.details.startTime <= block.timestamp, "Listing has not started");
        require(listing.details.endTime > block.timestamp || listing.details.startTime == 0, "Listing is expired");

        uint24 initialTotalSold = listing.totalSold;
        listing.totalSold += count*listing.details.totalPerSale;
        require(listing.totalSold <= listing.details.totalAvailable, "Not enough left");

        // If startTime is 0, start on first purchase
        if (listing.details.startTime == 0) {
            listing.details.startTime = uint48(block.timestamp);
            listing.details.endTime += uint48(block.timestamp);
        }

        uint256 totalPrice = _computeTotalPrice(listing, initialTotalSold, count);
        if (listing.details.erc20 == address(0)) {
          if (listing.details.type_ == MarketplaceLib.ListingType.DYNAMIC_PRICE) {
              // For dynamic price auctions, price may have changed so allow for a mismatch of funds sent
              receiveTokens(listing, msg.sender, totalPrice, true, false);
          } else {
              receiveTokens(listing, msg.sender, totalPrice, false, true);
          }
        } else {
          require(msg.value == 0, "Invalid amount");
        }
        
        // Identity verifier check
        if (listing.details.identityVerifier != address(0)) {
            require(IIdentityVerifier(listing.details.identityVerifier).verify(listingId, msg.sender, listing.token.address_, listing.token.id, count, totalPrice, listing.details.erc20, data), "Permission denied");
        }

        if (listing.token.lazy) {
            // Lazy delivered
            deliverTokenLazy(listingId, listing, msg.sender, count, totalPrice, 0);
        } else {
            // Single item
            deliverToken(listing, msg.sender, count, totalPrice, false);
        }

        // Automatically finalize listing if all sold
        if (listing.details.totalAvailable == listing.totalSold) {
            listing.flags |= MarketplaceLib.FLAG_MASK_FINALIZED;
        }

        // Pay seller
        if (listing.details.erc20 == address(0)) {
          _paySeller(royaltyEngineV1, listing, address(this), totalPrice, referrer, feesCollected);
        } else {
          _paySeller(royaltyEngineV1, listing, msg.sender, totalPrice, referrer, feesCollected);
        }
        
        emit MarketplaceLib.PurchaseEvent(listingId, referrer, msg.sender, count, totalPrice);
    }

    /**
     * Bid logic
     */
    function _preBidCheck(uint40 listingId, MarketplaceLib.Listing storage listing, uint256 bidAmount, bytes memory data) private {
        require(MarketplaceLib.isAuction(listing.details.type_), "Not available to bid");
        require(listing.details.startTime <= block.timestamp, "Listing has not started");
        require(listing.details.endTime > block.timestamp || listing.details.startTime == 0, "Listing is expired");

        // If startTime is 0, start on first purchase
        if (listing.details.startTime == 0) {
            listing.details.startTime = uint48(block.timestamp);
            listing.details.endTime += uint48(block.timestamp);
        }

        // Identity verifier check
        if (listing.details.identityVerifier != address(0)) {
            require(IIdentityVerifier(listing.details.identityVerifier).verify(listingId, msg.sender, listing.token.address_, listing.token.id, 1, bidAmount, listing.details.erc20, data), "Permission denied");
        }
    }

    function _postBidExtension(MarketplaceLib.Listing storage listing) private {
        if (listing.details.extensionInterval > 0 && listing.details.endTime <= (block.timestamp + listing.details.extensionInterval)) {
             // Extend auction time if necessary
             listing.details.endTime = uint48(block.timestamp) + listing.details.extensionInterval;
        }    
    }

    function performBid(uint40 listingId, MarketplaceLib.Listing storage listing, uint256 bidAmount, address payable referrer, bool increase, mapping(address => mapping(address => uint256)) storage escrow, bytes memory data) public {
        // Basic auction
        _preBidCheck(listingId, listing, bidAmount, data);

        address payable bidder = payable(msg.sender);
        MarketplaceLib.Bid storage currentBid = listing.bid;
        if (MarketplaceLib.hasBid(listing.flags)) {
            if (currentBid.bidder == bidder) {
                // Bidder is the current high bidder
                require(bidAmount > 0 && increase, "Existing bid");
                receiveTokens(listing, bidder, bidAmount, false, true);
                bidAmount += currentBid.amount;
            } else {
                // Bidder is not the current high bidder
                // Check minimum bid requirements
                require(bidAmount >= computeMinBid(listing.details.initialAmount, currentBid.amount, listing.details.minIncrementBPS), "Minimum bid not met");
                receiveTokens(listing, bidder, bidAmount, false, true);
                // Refund bid amount
                refundTokens(listing.details.erc20, currentBid.bidder, currentBid.amount, escrow);
            }
        } else {
            // Check minimum bid requirements
            require(bidAmount >= listing.details.initialAmount, "Invalid bid amount");
            // Set has bid flag first to prevent re-entrancy
            listing.flags |= MarketplaceLib.FLAG_MASK_HAS_BID;
            receiveTokens(listing, bidder, bidAmount, false, true);
        }
        // Update referrer if necessary
        if (currentBid.referrer != referrer && listing.referrerBPS > 0) currentBid.referrer = referrer;
        // Update bidder if necessary
        if (currentBid.bidder != bidder) currentBid.bidder = bidder;
        // Update amount and timestamp
        currentBid.amount = bidAmount;
        currentBid.timestamp = uint48(block.timestamp);
        emit MarketplaceLib.BidEvent(listingId, referrer, bidder, bidAmount);

        _postBidExtension(listing);
    }

    /**
     * Offer logic
     */
    function makeOffer(uint40 listingId, MarketplaceLib.Listing storage listing, uint256 offerAmount, address payable referrer, mapping (address => MarketplaceLib.Offer) storage offers, EnumerableSet.AddressSet storage offerAddresses, bool increase, bytes memory data) public {
        require(MarketplaceLib.canOffer(listing.details.type_, listing.flags), "Cannot make offer");
        require(offerAmount <= 0xffffffffffffffffffffffffffffffffffffffffffffffffff);
        require(listing.details.startTime <= block.timestamp, "Listing has not started");
        require(listing.details.endTime > block.timestamp || listing.details.startTime == 0, "Listing is expired");
        // Identity verifier check
        if (listing.details.identityVerifier != address(0)) {
            require(IIdentityVerifier(listing.details.identityVerifier).verify(listingId, msg.sender, listing.token.address_, listing.token.id, 1, offerAmount, listing.details.erc20, data), "Permission denied");
        }

        receiveTokens(listing, payable(msg.sender), offerAmount, false, true);
        MarketplaceLib.Offer storage currentOffer = offers[msg.sender];
        currentOffer.timestamp = uint48(block.timestamp);
        if (offerAddresses.contains(msg.sender)) {
            // Has existing offer, increase offer
            require(increase, "Existing offer");
            currentOffer.amount += uint200(offerAmount);
        } else {
            offerAddresses.add(msg.sender);
            currentOffer.amount = uint200(offerAmount);
            currentOffer.referrer = referrer;
        }
        emit MarketplaceLib.OfferEvent(listingId, referrer, msg.sender, currentOffer.amount);
    }

    function rescindOffer(uint40 listingId, MarketplaceLib.Listing storage listing, address offerAddress, mapping (address => MarketplaceLib.Offer) storage offers, EnumerableSet.AddressSet storage offerAddresses) public {
        require(offerAddresses.contains(offerAddress), "No offers found");
        MarketplaceLib.Offer storage currentOffer = offers[offerAddress];
        require(!currentOffer.accepted, "Offer already accepted");
        uint256 offerAmount = currentOffer.amount;

        // Remove offers first to prevent re-entrancy
        offerAddresses.remove(offerAddress);
        delete offers[offerAddress];

        refundTokens(listing.details.erc20, payable(offerAddress), offerAmount);

        emit MarketplaceLib.RescindOfferEvent(listingId, offerAddress, offerAmount);
    }

    /**
     * Deliver tokens
     */
    function deliverToken(MarketplaceLib.Listing storage listing, address to, uint24 count, uint256 payableAmount, bool reverse) public {
        // Check listing deliver fees if applicable
        if (payableAmount > 0 && (listing.fees.deliverBPS > 0 || listing.fees.deliverFixed > 0)) {
            uint256 deliveryFee = computeDeliverFee(listing, payableAmount);
            receiveTokens(listing, msg.sender, deliveryFee, false, true);
            // Pay out
            distributeProceeds(listing, address(this), deliveryFee);
        }
        
        if (listing.token.spec == TokenLib.Spec.ERC721) {
            require(count == 1, "Invalid amount");
            TokenLib._erc721Transfer(listing.token.address_, listing.token.id, address(this), to);
        } else if (listing.token.spec == TokenLib.Spec.ERC1155) {
            if (!reverse) {
                TokenLib._erc1155Transfer(listing.token.address_, listing.token.id, listing.details.totalPerSale*count, address(this), to);
            } else if (listing.details.totalAvailable > listing.totalSold) {
                require(count == 1, "Invalid amount");
                TokenLib._erc1155Transfer(listing.token.address_, listing.token.id, listing.details.totalAvailable-listing.totalSold, address(this), to);
            }
        } else {
            revert("Unsupported token spec");
        }
    }

    /**
     * Deliver lazy tokens
     */
    function deliverTokenLazy(uint40 listingId, MarketplaceLib.Listing storage listing, address to, uint24 count, uint256 payableAmount, uint256 index) public {
        // Check listing deliver fees if applicable
        if (payableAmount > 0 && (listing.fees.deliverBPS > 0 || listing.fees.deliverFixed > 0)) {
            // Receive tokens for fees
            uint256 deliveryFee = computeDeliverFee(listing, payableAmount);
            receiveTokens(listing, msg.sender, deliveryFee, false, true);
            // Pay out
            distributeProceeds(listing, address(this), deliveryFee);
        }

        // Call deliver (which can mint)
        ILazyDelivery(listing.token.address_).deliver(listingId, to, listing.token.id, count, payableAmount, listing.details.erc20, index);
    }


    /**
     * Distribute proceeds
     */
    function distributeProceeds(MarketplaceLib.Listing storage listing, address source, uint256 amount) public {
        if (listing.receivers.length > 0) {
            uint256 totalSent;
            uint256 receiverIndex;
            for (receiverIndex; receiverIndex < listing.receivers.length-1;) {
                uint256 receiverAmount = amount*listing.receivers[receiverIndex].receiverBPS/10000;
                sendTokens(listing.details.erc20, source, listing.receivers[receiverIndex].receiver, receiverAmount);
                totalSent += receiverAmount;
                unchecked { ++receiverIndex; }
            }
            require(totalSent < amount, "Settlement error");
            sendTokens(listing.details.erc20, source, listing.receivers[receiverIndex].receiver, amount-totalSent);
        } else {
            sendTokens(listing.details.erc20, source, listing.seller, amount);
        }
    }

    /**
     * Receive tokens.  Returns amount received.
     */
    function receiveTokens(MarketplaceLib.Listing storage listing, address source, uint256 amount, bool refundExcess, bool strict) public {
        if (source == address(this)) return;

        if (listing.details.erc20 == address(0)) {
            if (strict) {
                require(msg.value == amount, msg.value < amount ? "Insufficient funds" : "Invalid amount");
            } else {
                if (msg.value < amount) {
                   revert("Insufficient funds");
                } else if (msg.value > amount && refundExcess) {
                    // Refund excess
                   (bool success, ) = payable(source).call{value:msg.value-amount}("");
                   require(success, "Token send failure");
                }
            }
        } else {
            require(msg.value == 0, "Invalid amount");
            require(IERC20(listing.details.erc20).transferFrom(source, address(this), amount), "Insufficient funds");
        }
    }

    /**
     * Send proceeds to receiver
     */
    function sendTokens(address erc20, address source, address payable to, uint256 amount) public {
        require(source != to, "Invalid send request");

        if (erc20 == address(0)) {
            (bool success,) = to.call{value:amount}("");
            require(success, "Token send failure");
        } else {
            if (source == address(this)) {
                require(IERC20(erc20).transfer(to, amount), "Insufficient funds");
            } else {
                require(IERC20(erc20).transferFrom(source, to, amount), "Insufficient funds");
            }
        }
    }

    /**
     * Refund tokens
     */
    function refundTokens(address erc20, address payable to, uint256 amount, mapping(address => mapping(address => uint256)) storage escrow) public {
        if (erc20 == address(0)) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = to.call{value:amount, gas:20000}("");
            if (!success) {
                escrow[to][erc20] += amount;
                emit Escrow(to, erc20, amount);
            }
        } else {
            try IERC20(erc20).transfer(to, amount) {
            } catch {
                escrow[to][erc20] += amount;
                emit Escrow(to, erc20, amount);
            }
        }
    }

    function refundTokens(address erc20, address payable to, uint256 amount) public {
        if (erc20 == address(0)) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = to.call{value:amount}("");
            require(success);
        } else {
            IERC20(erc20).transfer(to, amount);
        }
    }

    /**
     * Compute deliver fee
     */
    function computeDeliverFee(MarketplaceLib.Listing memory listing, uint256 price) public pure returns(uint256) {
        return price*listing.fees.deliverBPS/10000 + listing.fees.deliverFixed;
    }

    /**
     * Compute current listing price
     */
    function computeListingPrice(MarketplaceLib.Listing storage listing) public view returns(uint256 currentPrice) {
        require(listing.details.endTime > block.timestamp || listing.details.startTime == 0 || !MarketplaceLib.isFinalized(listing.flags), "Listing is expired");
        currentPrice = listing.details.initialAmount;
        if (listing.details.type_ == MarketplaceLib.ListingType.DYNAMIC_PRICE) {
            currentPrice = IPriceEngine(listing.token.address_).price(listing.token.id, listing.totalSold, 1);
        } else {
            if (MarketplaceLib.hasBid(listing.flags)) {
                if (listing.details.type_ == MarketplaceLib.ListingType.INDIVIDUAL_AUCTION) {
                    currentPrice = computeMinBid(listing.details.initialAmount, listing.bid.amount, listing.details.minIncrementBPS);
                }
            }
        }
        return currentPrice;
    }

    /**
     * Compute total price for a <COUNT> of items to buy
     */
    function computeTotalPrice(MarketplaceLib.Listing storage listing, uint24 count) public view returns(uint256) {
        require(listing.details.endTime > block.timestamp || listing.details.startTime == 0 || !MarketplaceLib.isFinalized(listing.flags), "Listing is expired");
        return _computeTotalPrice(listing, listing.totalSold, count);
    }

    function _computeTotalPrice(MarketplaceLib.Listing storage listing, uint24 totalSold, uint24 count) private view returns(uint256) {
        if (listing.details.type_ != MarketplaceLib.ListingType.DYNAMIC_PRICE) {
            return listing.details.initialAmount*count;
        } else {
            return IPriceEngine(listing.token.address_).price(listing.token.id, totalSold, count);
        }
    }

    /**
     * Get the min bid
     */
    function computeMinBid(uint256 baseAmount, uint256 currentAmount, uint16 minIncrementBPS) pure public returns (uint256) {
        if (currentAmount == 0) {
            return baseAmount;
        }
        if (minIncrementBPS == 0) {
           return currentAmount+1;
        }
        uint256 incrementAmount = currentAmount*minIncrementBPS/10000;
        if (incrementAmount == 0) incrementAmount = 1;
        return currentAmount + incrementAmount;
    }

    /**
     * Helper to settle bid, which pays seller
     */
    function settleBid(address royaltyEngineV1, MarketplaceLib.Bid storage bid, MarketplaceLib.Listing storage listing, mapping(address => uint256) storage feesCollected) public {
        settleBid(royaltyEngineV1, bid, listing, 0, feesCollected);
    }

    function settleBid(address royaltyEngineV1, MarketplaceLib.Bid storage bid, MarketplaceLib.Listing storage listing, uint256 refundAmount, mapping(address => uint256) storage feesCollected) public {
        require(!bid.refunded, "Bid has been refunded");

        if (!bid.settled) {
            // Set to settled first to prevent re-entrancy
            bid.settled = true;
            _paySeller(royaltyEngineV1, listing, address(this), bid.amount-refundAmount, bid.referrer, feesCollected);
        }
    }

    /**
     * Refund bid
     */
    function refundBid(MarketplaceLib.Bid storage bid, MarketplaceLib.Listing storage listing, uint256 holdbackBPS, mapping(address => mapping(address => uint256)) storage escrow) public {
        require(!bid.settled, "Cannot refund, already settled");
        if (!bid.refunded) {
            // Set to refunded first to prevent re-entrancy
            bid.refunded = true;
            _refundBid(bid.bidder, bid.amount, listing, holdbackBPS, escrow);
        }
    }
    function _refundBid(address payable bidder, uint256 amount, MarketplaceLib.Listing storage listing, uint256 holdbackBPS, mapping(address => mapping(address => uint256)) storage escrow) private {
        uint256 refundAmount = amount;

        // Refund amount (less holdback)
        if (holdbackBPS > 0) {
            uint256 holdbackAmount = refundAmount*holdbackBPS/10000;
            refundAmount -= holdbackAmount;
            // Distribute holdback
            distributeProceeds(listing, address(this), holdbackAmount);
        }
        // Refund bidder
        refundTokens(listing.details.erc20, bidder, refundAmount, escrow);
    }

    /**
     * Helper to settle offer, which pays seller
     */
    function settleOffer(address royaltyEngineV1, uint40 listingId, MarketplaceLib.Listing storage listing, MarketplaceLib.Offer storage offer, address payable offerAddress, mapping(address => uint256) storage feesCollected, uint256 maxAmount, mapping(address => mapping(address => uint256)) storage escrow) public {
        require(!offer.accepted, "Already settled");

        // Set to accepted first to prevent re-entrancy
        offer.accepted = true;
        uint256 offerAmount = offer.amount;
        if (maxAmount > 0 && maxAmount < offerAmount) {
            // Refund the difference
            refundTokens(listing.details.erc20, offerAddress, offerAmount-maxAmount, escrow);
            // Set offerAmount to the max amount
            offerAmount = maxAmount;
        }
        _paySeller(royaltyEngineV1, listing, address(this), offerAmount, offer.referrer, feesCollected);
        emit MarketplaceLib.AcceptOfferEvent(listingId, offerAddress, offerAmount);
    }

    /**
     * Helper to pay seller given amount
     */
    function _paySeller(address royaltyEngineV1, MarketplaceLib.Listing storage listing, address source, uint256 amount, address payable referrer, mapping(address => uint256) storage feesCollected) private {
        uint256 sellerAmount = amount;
        if (listing.marketplaceBPS > 0) {
            uint256 marketplaceAmount = amount*listing.marketplaceBPS/10000;
            sellerAmount -= marketplaceAmount;
            receiveTokens(listing, source, marketplaceAmount, false, false);
            feesCollected[listing.details.erc20] += marketplaceAmount;
        }
        if (listing.referrerBPS > 0 && referrer != address(0)) {
            uint256 referrerAmount = amount*listing.referrerBPS/10000;
            sellerAmount -= referrerAmount;
            sendTokens(listing.details.erc20, source, referrer, referrerAmount);
        }

        if (!MarketplaceLib.sellerIsTokenCreator(listing.flags) && !listing.token.lazy) {
            // Handle royalties if not listed by token creator and not a lazy mint (lazy mints don't have royalties)
            try IRoyaltyEngineV1(royaltyEngineV1).getRoyalty(listing.token.address_, listing.token.id, amount) returns (address payable[] memory recipients, uint256[] memory amounts) {
                // Only pay royalties if properly configured
                if (recipients.length > 1 || (recipients.length == 1 && recipients[0] != listing.seller && recipients[0] != address(0))) {
                    for (uint i; i < recipients.length;) {
                        if (recipients[i] != address(0) && amounts[i] > 0) {
                            sellerAmount -= amounts[i];
                            sendTokens(listing.details.erc20, source, recipients[i], amounts[i]);
                        }
                        unchecked { ++i; }
                    }
                }
            } catch {}
        }
        distributeProceeds(listing, source, sellerAmount);
    }

}