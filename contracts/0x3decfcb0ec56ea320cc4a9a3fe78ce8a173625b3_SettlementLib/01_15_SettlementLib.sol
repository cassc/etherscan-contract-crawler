// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@manifoldxyz/royalty-registry-solidity/contracts/IRoyaltyEngineV1.sol";

import "../IIdentityVerifier.sol";
import "../ILazyDelivery.sol";
import "../IPriceEngine.sol";

import "./MarketplaceLib.sol";
import "./TokenLib.sol";
import "./BidTreeLib.sol";

/**
 * @dev Marketplace settlement logic
 */
library SettlementLib {

    using BidTreeLib for BidTreeLib.BidTree;

    event Escrow(address indexed receiver, address erc20, uint256 amount);

    /**
     * Purchase logic
     * Assumes that listing.totalSold has been pre-incremented and checked against listing.details.totalAvailable
     */
    function performPurchase(address royaltyEngineV1, address payable referrer, uint40 listingId, MarketplaceLib.Listing storage listing, uint24 count, mapping(address => uint256) storage feesCollected, bytes memory data) public {
        require(listing.details.type_ == MarketplaceLib.ListingType.FIXED_PRICE || listing.details.type_ == MarketplaceLib.ListingType.DYNAMIC_PRICE, "Not available to purchase");
        require(listing.details.startTime <= block.timestamp, "Listing has not started");
        require(listing.details.endTime > block.timestamp || listing.details.startTime == 0, "Listing is expired");

        // If startTime is 0, start on first purchase
        if (listing.details.startTime == 0) {
            listing.details.startTime = uint48(block.timestamp);
            listing.details.endTime += uint48(block.timestamp);
        }

        uint256 totalPrice = computeTotalPrice(listing, count, true);
        if (listing.details.type_ == MarketplaceLib.ListingType.DYNAMIC_PRICE) {
            // For dynamic price auctions, price may have changed so allow for a mismatch of funds sent
            receiveTokens(listing, msg.sender, totalPrice, true, false);
        } else {
            receiveTokens(listing, msg.sender, totalPrice, false, true);
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
        _paySeller(royaltyEngineV1, listing, address(this), totalPrice, referrer, feesCollected);
        emit MarketplaceLib.PurchaseEvent(listingId, referrer, msg.sender, count, totalPrice);
    }


    /**
     * Bid logic
     */
    function _preBidCheck(uint40 listingId, MarketplaceLib.Listing storage listing, uint256 bidAmount, bytes memory data) private {
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

    function performBidIndividual(uint40 listingId, MarketplaceLib.Listing storage listing, uint256 bidAmount, address payable referrer, bool increase, mapping(address => mapping(address => uint256)) storage escrow, bytes memory data) public {
        // Basic auction
        _preBidCheck(listingId, listing, bidAmount, data);

        address payable bidder = payable(msg.sender);
        MarketplaceLib.Bid storage currentBid = listing.bid;
        if ((listing.flags & MarketplaceLib.FLAG_MASK_HAS_BID) != 0) {
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
            receiveTokens(listing, bidder, bidAmount, false, true);
            listing.flags |= MarketplaceLib.FLAG_MASK_HAS_BID;
        }
        // Update referrer if necessary
        if (currentBid.referrer != referrer && listing.referrerBPS > 0) currentBid.referrer = referrer;
        // Update bidder if necessary
        if (currentBid.bidder != bidder) currentBid.bidder = bidder;
        // Update amount
        currentBid.amount = bidAmount;
        emit MarketplaceLib.BidEvent(listingId, referrer, bidder, bidAmount);

        _postBidExtension(listing);
    }

    function performBidRanked(uint40 listingId, MarketplaceLib.Listing storage listing, BidTreeLib.BidTree storage bidTree, uint256 bidAmount, bool increase, mapping(address => mapping(address => uint256)) storage escrow, bytes memory data) public {
        // Ranked auction
        _preBidCheck(listingId, listing, bidAmount, data);

        address payable bidder = payable(msg.sender);
        if ((listing.flags & MarketplaceLib.FLAG_MASK_HAS_BID) != 0 && bidTree.exists(bidder)) {
            // Has already bid, this is a bid update
            BidTreeLib.Bid storage currentBid = bidTree.getBid(bidder);
            require(increase, "Existing bid");
            receiveTokens(listing, bidder, bidAmount, false, true);
            uint256 newBidAmount = currentBid.amount + bidAmount;
            bidTree.remove(bidder);
            bidTree.insert(bidder, newBidAmount, uint48(block.timestamp));
            emit MarketplaceLib.BidEvent(listingId, address(0), bidder, newBidAmount);
        } else {
            // Has not yet bid
            require(bidAmount >= listing.details.initialAmount, "Invalid bid amount");
            if (bidTree.size == listing.details.totalAvailable) {
                address payable lowestBidder = payable(bidTree.last());
                BidTreeLib.Bid storage lowestBid = bidTree.getBid(lowestBidder);
                // At max bids, so this bid must be greater than the lowest bid
                require(bidAmount >= computeMinBid(listing.details.initialAmount, lowestBid.amount, listing.details.minIncrementBPS), "Minimum bid not met");
                // Receive amount
                receiveTokens(listing, bidder, bidAmount, false, true);
                // Return lowest bid amount
                refundTokens(listing.details.erc20, lowestBidder, lowestBid.amount, escrow);
                bidTree.remove(lowestBidder);
                bidTree.insert(bidder, bidAmount, uint48(block.timestamp));
            } else {
                // Receive amount
                receiveTokens(listing, bidder, bidAmount, false, true);
                // Still have bid slots left.
                bidTree.insert(bidder, bidAmount, uint48(block.timestamp));
                listing.flags |= MarketplaceLib.FLAG_MASK_HAS_BID;
            }
            emit MarketplaceLib.BidEvent(listingId, address(0), bidder, bidAmount);
        }

        _postBidExtension(listing);
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
    function deliverTokenLazy(uint40 listingId, MarketplaceLib.Listing storage listing, address to, uint24 count, uint256 payableAmount, uint256 index) public returns(uint256) {
        // Check listing deliver fees if applicable
        if (payableAmount > 0 && (listing.fees.deliverBPS > 0 || listing.fees.deliverFixed > 0)) {
            // Receive tokens for fees
            uint256 deliveryFee = computeDeliverFee(listing, payableAmount);
            receiveTokens(listing, msg.sender, deliveryFee, false, true);
            // Pay out
            distributeProceeds(listing, address(this), deliveryFee);
        }

        // Call deliver (which can mint)
        return ILazyDelivery(listing.token.address_).deliver(listingId, to, listing.token.id, count, payableAmount, listing.details.erc20, index);
    }


    /**
     * Distribute proceeds
     */
    function distributeProceeds(MarketplaceLib.Listing storage listing, address source, uint256 amount) public {
        if (listing.receivers.length > 0) {
            uint256 totalSent;
            uint256 receiverIndex;
            for (receiverIndex = 0; receiverIndex < listing.receivers.length-1; receiverIndex++) {
                uint256 receiverAmount = amount*listing.receivers[receiverIndex].receiverBPS/10000;
                sendTokens(listing.details.erc20, source, listing.receivers[receiverIndex].receiver, receiverAmount);
                totalSent += receiverAmount;
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
                   require(success);
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
            require(success);
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

    /**
     * Compute deliver fee
     */
    function computeDeliverFee(MarketplaceLib.Listing memory listing, uint256 price) public pure returns(uint256) {
        return price*listing.fees.deliverBPS/10000 + listing.fees.deliverFixed;
    }

    /**
     * Compute current listing price
     */
    function computeListingPrice(MarketplaceLib.Listing storage listing, BidTreeLib.BidTree storage bidTree) public view returns(uint256 currentPrice) {
        currentPrice = listing.details.initialAmount;
        if (listing.details.type_ == MarketplaceLib.ListingType.DYNAMIC_PRICE) {
            currentPrice = IPriceEngine(listing.token.address_).price(listing.token.id, listing.totalSold, 1);
        } else {
            if ((listing.flags & MarketplaceLib.FLAG_MASK_HAS_BID) != 0) {
                if (listing.details.type_ == MarketplaceLib.ListingType.INDIVIDUAL_AUCTION) {
                    currentPrice = computeMinBid(listing.details.initialAmount, listing.bid.amount, listing.details.minIncrementBPS);
                } else if (listing.details.type_ == MarketplaceLib.ListingType.RANKED_AUCTION && bidTree.size == listing.details.totalAvailable) {
                    currentPrice = computeMinBid(listing.details.initialAmount, bidTree.getBid(bidTree.last()).amount, listing.details.minIncrementBPS);
                }
            }
        }
        return currentPrice;
    }

    /**
     * Compute total price for a <COUNT> of items to buy
     */
    function computeTotalPrice(MarketplaceLib.Listing storage listing, uint24 count, bool totalSoldIncreased) public view returns(uint256) {
        if (listing.details.type_ != MarketplaceLib.ListingType.DYNAMIC_PRICE) {
            return listing.details.initialAmount*count;
        } else {
            if (totalSoldIncreased) {
                // If totalSold value was increased prior to call, need to reduce it in order to get the proper pricing
                return IPriceEngine(listing.token.address_).price(listing.token.id, listing.totalSold-count*listing.details.totalPerSale, count);
            } else {
                return IPriceEngine(listing.token.address_).price(listing.token.id, listing.totalSold, count);
            }
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
        return currentAmount*(10000+minIncrementBPS)/10000;
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
            _paySeller(royaltyEngineV1, listing, address(this), bid.amount-refundAmount, bid.referrer, feesCollected);
            bid.settled = true;
        }
    }
    function settleBid(address royaltyEngineV1, BidTreeLib.Bid storage bid, MarketplaceLib.Listing storage listing, mapping(address => uint256) storage feesCollected) public {
        settleBid(royaltyEngineV1, bid, listing, 0, feesCollected);
    }

    function settleBid(address royaltyEngineV1, BidTreeLib.Bid storage bid, MarketplaceLib.Listing storage listing, uint256 refundAmount, mapping(address => uint256) storage feesCollected) public {
        require(!bid.refunded, "Bid has been refunded");
        if (!bid.settled) {
            _paySeller(royaltyEngineV1, listing, address(this), bid.amount-refundAmount, payable(address(0)), feesCollected);
            bid.settled = true;
        }
    }

    /**
     * Refund bid
     */
    function refundBid(address payable bidder, BidTreeLib.Bid storage bid, MarketplaceLib.Listing storage listing, uint256 holdbackBPS, mapping(address => mapping(address => uint256)) storage escrow) public {
        require(!bid.settled, "Cannot refund, already settled");
        if (!bid.refunded) {
            _refundBid(bidder, bid.amount, listing, holdbackBPS, escrow);
            bid.refunded = true;
        }
    }
    function refundBid(MarketplaceLib.Bid storage bid, MarketplaceLib.Listing storage listing, uint256 holdbackBPS, mapping(address => mapping(address => uint256)) storage escrow) public {
        require(!bid.settled, "Cannot refund, already settled");
        if (!bid.refunded) {
            _refundBid(bid.bidder, bid.amount, listing, holdbackBPS, escrow);
            bid.refunded = true;
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

        if ((listing.flags & MarketplaceLib.FLAG_MASK_TOKEN_CREATOR == 0) && !listing.token.lazy) {
            // Handle royalties if not listed by token creator and not a lazy mint (lazy mints don't have royalties)
            try IRoyaltyEngineV1(royaltyEngineV1).getRoyalty(listing.token.address_, listing.token.id, amount) returns (address payable[] memory recipients, uint256[] memory amounts) {
                // Only pay royalties if properly configured
                if (recipients.length > 1 || (recipients.length == 1 && recipients[0] != listing.seller && recipients[0] != address(0))) {
                    for (uint i = 0; i < recipients.length; i++) {
                        if (recipients[i] != address(0) && amounts[i] > 0) {
                            sellerAmount -= amounts[i];
                            sendTokens(listing.details.erc20, source, recipients[i], amounts[i]);
                        }
                    }
                }
            } catch {}
        }
        distributeProceeds(listing, source, sellerAmount);
    }

}