// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../IIdentityVerifier.sol";
import "../ILazyDelivery.sol";
import "../IPriceEngine.sol";

import "./IRoyalty.sol";
import "./MarketplaceLib.sol";
import "./TokenLib.sol";
import "./BidTreeLib.sol";

/**
 * @dev Marketplace settlement logic
 */
library SettlementLib {

    using BidTreeLib for BidTreeLib.BidTree;

    bytes32 internal constant erc721bytes32 = keccak256(bytes('erc721'));
    bytes32 internal constant erc1155bytes32 = keccak256(bytes('erc1155'));


    /**
     * bytes4(keccak256('getRoyalties(uint256)')) == 0xbb3bafd6
     */
    bytes4 public constant INTERFACE_ID_ROYALTIES_CREATORCORE = 0xbb3bafd6;

    /**
     * bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
     * bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
     */
    bytes4 public constant INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

    /**
     * bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
     */
    bytes4 public constant INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;

    event Escrow(address indexed receiver, address erc20, uint256 amount);

    /**
     * Purchase logic
     */
    function performPurchase(address tokenReceiver, address payable referrer, address purchaser, MarketplaceLib.Listing storage listing, mapping(address => uint256) storage feesCollected) public {
        require(listing.details.type_ == MarketplaceLib.ListingType.FIXED_PRICE || listing.details.type_ == MarketplaceLib.ListingType.DYNAMIC_PRICE, "Not available to purchase");
        require(purchaser != listing.seller, "Cannot buy your own item");
        require(listing.id > 0, "Listing not found");
        require(listing.details.startTime <= block.timestamp, "Listing has not started");
        require((listing.details.endTime > block.timestamp && !listing.finalized) || listing.details.startTime == 0, "Listing is expired");

        // If startTime is 0, start on first purchase
        if (listing.details.startTime == 0) {
            listing.details.startTime = uint48(block.timestamp);
            listing.details.endTime += uint48(block.timestamp);
        }

        uint256 currentPrice;
        if (listing.details.type_ != MarketplaceLib.ListingType.DYNAMIC_PRICE) {
            currentPrice = listing.details.initialAmount;
        } else {
            currentPrice = IPriceEngine(listing.token.address_).price(listing.token.id, listing.totalSold);
        }
        uint256 deliveryFee = computeDeliverFee(listing, currentPrice);
        receiveTokens(listing, msg.sender, currentPrice+deliveryFee, listing.details.type_ == MarketplaceLib.ListingType.DYNAMIC_PRICE, listing.details.type_ != MarketplaceLib.ListingType.DYNAMIC_PRICE);
        
        if (listing.token.lazy) {
            // Lazy delivered
            deliverTokenLazy(listing, purchaser, currentPrice, 0);
        } else {
            // Single item
            deliverToken(tokenReceiver, listing, purchaser, currentPrice, false);
        }
        if (listing.details.totalAvailable == listing.totalSold) {
            listing.finalized = true;
        }

        // Pay seller
        paySeller(listing, address(this), currentPrice, referrer, feesCollected);
        emit MarketplaceLib.PurchaseEvent(listing.id, referrer == address(1) ? address(0) : referrer, purchaser, currentPrice);
    }


    /**
     * Bid logic
     */
    function performBid(uint256 bidAmount, address payable referrer, address payable bidder, MarketplaceLib.Listing storage listing, BidTreeLib.BidTree storage bidTree, bool increase, mapping(address => mapping(address => uint256)) storage escrow) public {
        require(bidder != listing.seller, "Cannot bid on your own item");
        require(listing.id > 0, "Listing not found");
        require(listing.details.startTime <= block.timestamp, "Listing has not started");
        require((listing.details.endTime > block.timestamp && !listing.finalized) || listing.details.startTime == 0, "Listing is expired");

        // If startTime is 0, start on first purchase
        if (listing.details.startTime == 0) {
            listing.details.startTime = uint48(block.timestamp);
            listing.details.endTime += uint48(block.timestamp);
        }

        if (listing.details.type_ == MarketplaceLib.ListingType.INDIVIDUAL_AUCTION) {
            _bidIndividual(bidAmount, referrer, bidder, listing, increase, escrow);
        } else if (listing.details.type_ == MarketplaceLib.ListingType.RANKED_AUCTION) {
            _bidRanked(bidAmount, referrer, bidder, listing, bidTree, increase, escrow);
        } else {
            // Invalid type
            revert("Invalid type");
        }

        if (listing.details.extensionInterval > 0 && listing.details.endTime <= (block.timestamp + listing.details.extensionInterval)) {
             // Extend auction time if necessary
             listing.details.endTime = uint48(block.timestamp) + listing.details.extensionInterval;
        }

    }

    function _bidIndividual(uint256 bidAmount, address payable referrer, address payable bidder, MarketplaceLib.Listing storage listing, bool increase, mapping(address => mapping(address => uint256)) storage escrow) private {
        // Basic auction
        MarketplaceLib.Bid storage currentBid = listing.bid;
        if (listing.hasBid) {
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
            listing.hasBid = true;
        }
        // Update referrer if necessary
        if (currentBid.referrer != referrer) currentBid.referrer = referrer;
        // Update bidder if necessary
        if (currentBid.bidder != bidder) currentBid.bidder = bidder;
        // Update amount
        currentBid.amount = bidAmount;
        emit MarketplaceLib.BidEvent(listing.id, referrer == address(1) ? address(0) : referrer, bidder, bidAmount);
    }

    function _bidRanked(uint256 bidAmount, address payable referrer, address payable bidder, MarketplaceLib.Listing storage listing, BidTreeLib.BidTree storage bidTree, bool increase, mapping(address => mapping(address => uint256)) storage escrow) private {
        // Ranked auction
        if (listing.hasBid && bidTree.exists(bidder)) {
            // Has already bid, this is a bid update
            BidTreeLib.Bid storage currentBid = bidTree.getBid(bidder);
            require(increase, "Existing bid");
            receiveTokens(listing, bidder, bidAmount, false, true);
            uint256 newBidAmount = currentBid.amount + bidAmount;
            referrer = currentBid.referrer;
            bidTree.remove(bidder);
            bidTree.insert(bidder, newBidAmount, uint48(block.timestamp), referrer);
            if (currentBid.referrer != referrer) currentBid.referrer = referrer;
            emit MarketplaceLib.BidEvent(listing.id, referrer == address(1) ? address(0) : referrer, bidder, newBidAmount);
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
                bidTree.insert(bidder, bidAmount, uint48(block.timestamp), referrer);
            } else {
                // Receive amount
                receiveTokens(listing, bidder, bidAmount, false, true);
                // Still have bid slots left.
                bidTree.insert(bidder, bidAmount, uint48(block.timestamp), referrer);
                listing.hasBid = true;
            }
            emit MarketplaceLib.BidEvent(listing.id, referrer == address(1) ? address(0) : referrer, bidder, bidAmount);
        }
    }

    /**
     * Deliver tokens
     */
    function deliverToken(address tokenReceiver, MarketplaceLib.Listing storage listing, address to, uint256 payableAmount, bool reverse) public {
        // Check listing deliver fees if applicable
        if (payableAmount > 0 && (listing.fees.deliverBPS > 0 || listing.fees.deliverFixed > 0)) {
            uint256 deliveryFee = computeDeliverFee(listing, payableAmount);
            receiveTokens(listing, msg.sender, deliveryFee, false, true);
            // Pay out
            distributeProceeds(listing, address(this), deliveryFee);
        }
        
        // Increment tokens sold
        if (!reverse) {
            listing.totalSold += listing.details.totalPerSale;
        }

        if (keccak256(bytes(listing.token.spec)) == TokenLib._erc721bytes32) {
            TokenLib._erc721Transfer(listing.token.address_, listing.token.id, address(this), to);
        } else if (keccak256(bytes(listing.token.spec)) == TokenLib._erc1155bytes32) {
            if (!reverse) {
                TokenLib._erc1155Transfer(tokenReceiver, listing.token.address_, listing.token.id, listing.details.totalPerSale, to);
            } else if (listing.details.totalAvailable > listing.totalSold) {
                TokenLib._erc1155Transfer(tokenReceiver, listing.token.address_, listing.token.id, listing.details.totalAvailable-listing.totalSold, to);
            }
        } else {
            revert("Unsupported token spec");
        }
    }

    /**
     * Deliver lazy tokens
     */
    function deliverTokenLazy(MarketplaceLib.Listing storage listing, address to, uint256 payableAmount, uint256 index) public returns(uint256) {
        // Check listing deliver fees if applicable
        if (payableAmount > 0 && (listing.fees.deliverBPS > 0 || listing.fees.deliverFixed > 0)) {
            // Receive tokens for fees
            uint256 deliveryFee = computeDeliverFee(listing, payableAmount);
            receiveTokens(listing, msg.sender, deliveryFee, false, true);
            // Pay out
            distributeProceeds(listing, address(this), deliveryFee);
        }

        // Increment tokens sold
        listing.totalSold += listing.details.totalPerSale;

        // Call deliver (which can mint)
        return ILazyDelivery(listing.token.address_).deliver(msg.sender, listing.id, listing.token.id, to, payableAmount, index);
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
            if (listing.details.identityVerifier != address(0)) require(IIdentityVerifier(listing.details.identityVerifier).verify(msg.sender, amount));
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
            if (listing.details.identityVerifier != address(0)) require(IIdentityVerifier(listing.details.identityVerifier).verify(msg.sender, source, amount));
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
            currentPrice = IPriceEngine(listing.token.address_).price(listing.token.id, listing.totalSold);
        } else {
            if (listing.hasBid) {
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
     * Helper to pay seller given amount
     */
    function paySeller(MarketplaceLib.Listing storage listing, address source, uint256 amount, address payable referrer, mapping(address => uint256) storage feesCollected) public {
        uint256 sellerAmount = amount;
        if (listing.fees.marketplaceBPS > 0) {
            uint256 marketplaceAmount = amount*listing.fees.marketplaceBPS/10000;
            sellerAmount -= marketplaceAmount;
            receiveTokens(listing, source, marketplaceAmount, false, false);
            feesCollected[listing.details.erc20] += marketplaceAmount;
        }
        if (listing.fees.referrerBPS > 0 && referrer != address(1)) {
            uint256 referrerAmount = amount*listing.fees.referrerBPS/10000;
            sellerAmount -= referrerAmount;
            sendTokens(listing.details.erc20, source, referrer, referrerAmount);
        }

        if (!listing.token.lazy) {
            // Handle royalties if not a lazy mint (lazy mints don't have royalties)
            address payable[] memory recipients;
            uint256[] memory recipientBPS;
            if (ERC165Checker.supportsInterface(listing.token.address_, INTERFACE_ID_ROYALTIES_CREATORCORE)) {
                (recipients, recipientBPS) = IRoyalty(listing.token.address_).getRoyalties(listing.token.id);
            } else if (ERC165Checker.supportsInterface(listing.token.address_, INTERFACE_ID_ROYALTIES_RARIBLE)) {
                recipients = IRoyalty(listing.token.address_).getFeeRecipients(listing.token.id);
                recipientBPS = IRoyalty(listing.token.address_).getFeeBps(listing.token.id);
            } else if (ERC165Checker.supportsInterface(listing.token.address_, INTERFACE_ID_ROYALTIES_EIP2981)) {
                (address recipient, uint256 royaltyAmount) = IRoyalty(listing.token.address_).royaltyInfo(listing.token.id, amount);
                if (recipient != address(0) && royaltyAmount != 0) {
                    recipients = new address payable[](1);
                    recipientBPS = new uint256[](1);
                    recipients[0] = payable(recipient);
                    recipientBPS[0] = (royaltyAmount*10000)/amount;
                }
            }
            require(recipients.length == recipientBPS.length, "Royalty error");
            if (recipients.length > 1 || (recipients.length == 1 && recipients[0] != listing.seller)) {
                for (uint i = 0; i < recipients.length; i++) {
                    uint256 royaltyAmount = amount*recipientBPS[i]/10000;
                    sellerAmount -= royaltyAmount;
                    sendTokens(listing.details.erc20, source, recipients[i], royaltyAmount);
                }
            }
        }
        distributeProceeds(listing, source, sellerAmount);
    }

    /**
     * Helper to settle bid, which pays seller
     */
    function settleBid(MarketplaceLib.Bid storage bid, MarketplaceLib.Listing storage listing, mapping(address => uint256) storage feesCollected) public {
        settleBid(bid, listing, 0, feesCollected);
    }

    function settleBid(MarketplaceLib.Bid storage bid, MarketplaceLib.Listing storage listing, uint256 refundAmount, mapping(address => uint256) storage feesCollected) public {
        require(!bid.refunded, "Bid has been refunded");
        if (!bid.settled) {
            paySeller(listing, address(this), bid.amount-refundAmount, bid.referrer, feesCollected);
            bid.settled = true;
        }
    }
    function settleBid(BidTreeLib.Bid storage bid, MarketplaceLib.Listing storage listing, mapping(address => uint256) storage feesCollected) public {
        settleBid(bid, listing, 0, feesCollected);
    }

    function settleBid(BidTreeLib.Bid storage bid, MarketplaceLib.Listing storage listing, uint256 refundAmount, mapping(address => uint256) storage feesCollected) public {
        require(!bid.refunded, "Bid has been refunded");
        if (!bid.settled) {
            paySeller(listing, address(this), bid.amount-refundAmount, bid.referrer, feesCollected);
            bid.settled = true;
        }
    }

    /**
     * Refund bid
     */
    function refundBid(MarketplaceLib.Bid storage bid, MarketplaceLib.Listing storage listing, uint256 holdbackBPS, mapping(address => mapping(address => uint256)) storage escrow) public {
        require(!bid.settled, "Cannot refund, already settled");
        if (!bid.refunded) {
            bid.refunded = true;
            uint256 refundAmount = bid.amount;

            // Refund amount (less holdback)
            if (holdbackBPS > 0) {
                uint256 holdbackAmount = refundAmount*holdbackBPS/10000;
                refundAmount -= holdbackAmount;
                // Distribute holdback
                distributeProceeds(listing, address(this), holdbackAmount);
            }
            // Refund bidder
            refundTokens(listing.details.erc20, bid.bidder, refundAmount, escrow);

        }
    }

    function refundBid(address payable bidder, BidTreeLib.Bid storage bid, MarketplaceLib.Listing storage listing, uint256 holdbackBPS, mapping(address => mapping(address => uint256)) storage escrow) public {
        require(!bid.settled, "Cannot refund, already settled");
        if (!bid.refunded) {
            bid.refunded = true;
            uint256 refundAmount = bid.amount;

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
    }

}