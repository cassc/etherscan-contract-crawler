/**
    playplanetx.com
    Planet-X Ltd © 2023 | All rights reserved
*/
// #region Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions
// #endregion

// SPDX-License-Identifier: UNLICENCED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./IXAuction.sol";
import "./AuctionStructs.sol";
import "../base/Withdrawer.sol";
import "../base/XNFTRoyaltyBase.sol";

error AlreadyClaimed(address claimaint);

abstract contract XAuctions is IXAuction, Withdrawer, XNFTRoyaltyBase {
    using SafeCast for uint256;
    using Math for uint256;

    uint8 public activeAuctionId;

    // the auctions data
    mapping(uint16 auctionId => Auction) public auctions;

    // users bids and refunds
    // auctionId -> userAddress -> User
    mapping(uint16 auctionId => mapping(address => Bidder)) public bidders;

    function _startClaims(uint8 _auctionId) internal {
        // read auction to memory
        Auction memory auction = auctions[_auctionId];

        // revert if the stage is not "bidding closed"
        if (auction.stage != AuctionStage.Closed) {
            revert StageMustBeBiddingClosed(auction.stage);
        }

        if (auction.price == 0) {
            revert PriceMustBeSet();
        }

        // write back to storage
        auctions[_auctionId].stage = AuctionStage.Claims;

        emit ClaimsAndRefundsStarted(_auctionId);
    }

    function _setPrice(uint8 _auctionId, uint64 newPrice) internal {
        // read auction to memory
        Auction memory auction = auctions[_auctionId];

        if (auction.stage != AuctionStage.Closed) {
            revert StageMustBeBiddingClosed(auction.stage);
        }

        uint64 minBid = auction.minimumBid; // storage to memory
        if (newPrice < minBid) {
            revert PriceIsLowerThanTheMinBid(newPrice, minBid);
        }
        auctions[auction.id].price = newPrice;
        emit PriceSet(_auctionId, newPrice);
    }

    function bid(uint8 auctionId) internal {
        if (auctions[auctionId].stage != AuctionStage.Active) {
            revert AuctionMustBeActive();
        }

        uint256 userBid = bidders[auctionId][msg.sender].totalBid;

        // increment the bid of the user
        userBid += msg.value;

        // if their new total bid is less than the current minimum bid
        // revert with an error
        uint64 minBid = auctions[auctionId].minimumBid;
        if (userBid < minBid) {
            revert BidLowerThanMinimum(userBid, minBid);
        }

        // save the bid
        bidders[auctionId][msg.sender].totalBid = SafeCast.toUint120(userBid);

        emit Bid(auctionId, msg.sender, msg.value, userBid);
    }

    function _startAuction(uint8 id) internal {
        if (auctions[id].stage != AuctionStage.None) {
            revert AuctionMustNotBeStarted();
        }

        auctions[id].stage = AuctionStage.Active;
        activeAuctionId = id;
        emit AuctionStarted(id);
    }

    function _saveNewAuction(
        uint8 _id,
        uint16 _supply,
        uint8 _maxWinPerWallet,
        uint64 _minimumBid
    ) internal {
        if (
            _supply == 0 ||
            _minimumBid == 0 ||
            _maxWinPerWallet == 0 ||
            _supply < _maxWinPerWallet
        ) {
            revert InvalidCreateAuctionParams();
        }

        // create the auction
        auctions[_id] = Auction({
            id: _id,
            maxWinPerWallet: _maxWinPerWallet,
            supply: _supply,
            remainingSupply: _supply,
            minimumBid: _minimumBid,
            price: 0,
            stage: AuctionStage.None
        });

        emit AuctionCreated(_id, _supply, _maxWinPerWallet, _minimumBid);
    }

    /**
     * @notice claim function to be used both by the user and by the support role
     * @dev used by claim() and claimOnBehalfOf()
     * @param claimant the address to claim tokens for.
     */
    function _internalClaim(address claimant, uint8 _auctionId) internal {
        // early revert if the auction is not in the right stage
        Auction memory auction = auctions[_auctionId];

        if (auction.stage < AuctionStage.Claims) {
            revert InvalidStageForOperation(auction.stage, AuctionStage.Claims);
        }

        // read user in memory
        Bidder memory user = bidders[_auctionId][claimant];

        // revert if the user has already claimed
        if (user.claimed) {
            revert AlreadyClaimed(claimant);
        }

        // @dev state modification CEI pattern
        bidders[_auctionId][claimant].claimed = true;

        uint120 userTotalBid = user.totalBid;

        if (userTotalBid == 0) {
            revert ZeroBids(claimant);
        }

        // determine the split between tokens and refund
        // limit to the maximum tokens a wallet can win in the auction
        uint mintAmount = Math.min(
            // @dev no precision loss in division below, we only need the whole part
            Math.min(userTotalBid / auction.price, auction.maxWinPerWallet),
            auction.remainingSupply
        );

        uint128 podsMintCost = uint128(mintAmount) * auction.price;

        // if any pods are won
        // the mintAmount is adjusted for supply above,
        // hence it can be 0 again if no supply has been left
        if (mintAmount > 0) {
            unchecked {
                // does not overflow, mintAmount is limited to the supply left
                auctions[_auctionId].remainingSupply = uint16(
                    auction.remainingSupply - mintAmount
                );

                // increase the withdrawable amount
                withdrawableFunds = withdrawableFunds + podsMintCost;
            }

            // mint the tokens
            _mint(claimant, mintAmount);
        }

        // send the refund
        uint128 refund = userTotalBid - podsMintCost;
        if (refund > 0) {
            // write the refund to state
            bidders[_auctionId][claimant].refundedFunds =
                user.refundedFunds +
                SafeCast.toUint120(refund);

            (bool success, ) = claimant.call{value: refund}("");
            if (!success) {
                revert RefundFailed(claimant, refund);
            }
            emit RefundSent(claimant, refund);
        }

        emit Claimed(claimant, userTotalBid, mintAmount, refund);
    }

    // function currentAuction() external view returns (Auction memory) {
    //     return auctions[activeAuction];
    // }
}