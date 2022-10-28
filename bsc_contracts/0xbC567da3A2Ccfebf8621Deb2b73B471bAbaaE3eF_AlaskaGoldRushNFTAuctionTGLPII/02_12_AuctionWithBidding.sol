//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./Auction.sol";
import { Bids } from "./domain/Bids.sol";

contract AuctionWithBidding is Auction {
    using SafeERC20 for IERC20;

    using Bids for Bids.Set;

    uint256 public openingBid;

    uint256 public startingBid = 100 ether;

    /// @notice a minimal increment of the next bid in relation to the previous bid
    uint256 public priceIncrementPercentage = 10;

    /// @notice increment (in seconds) of time remaining to outbid after someone bid
    uint256 public outbiddingTimeframe = 10 minutes;

    bytes32 public lotBatchRoot;

    Bids.Set private bids;

    /* Configuration
     ****************************************************************/

    function setOpeningBid(uint256 openingBid_) external onlyOwner {
        openingBid = openingBid_;
    }

    function setStartingBid(uint256 startingBid_) external onlyOwner {
        startingBid = startingBid_;
    }

    function setOutbiddingTimeframe(uint256 outbiddingTimeframe_) external onlyOwner {
        outbiddingTimeframe = outbiddingTimeframe_;
    }

    function setPriceIncrementPercentage(uint256 priceIncrementPercentage_) external onlyOwner {
        require(priceIncrementPercentage_ > 0, "Price increment too low");
        priceIncrementPercentage = priceIncrementPercentage_;
    }

    function setLotBatchRoot(bytes32 lotBatchRoot_) external onlyOwner {
        lotBatchRoot = lotBatchRoot_;
    }

    /* Domain
     ****************************************************************/

    function bid(
        uint256 lotKey,
        uint256 amount,
        address currency,
        bytes32[] calldata lotBatchProof,
        bytes32[] calldata whitelistProof
    ) external onlyWhitelisted(whitelistProof) {
        require(isAvailable(lotKey, lotBatchProof), "Lot batch mismatch");

        require(isAvailableCurrency(currency), "Currency is not available");

        require(!bids.isTopBidder(_msgSender()), "Bidder is already a leader");

        Bids.Item memory topBid = bids.getTopBidByLot(lotKey);

        bool isInOutbiddingTimeframe = topBid.bidder == address(0) ||
            (block.timestamp >= topBid.timestamp && block.timestamp <= topBid.timestamp + outbiddingTimeframe);

        require(isInOutbiddingTimeframe, "Lot out of outbidding timeframe");

        require(isValidBidAmount(amount, topBid.amount, topBid.bidder == address(0)), "Bid amount invalid");

        if (amount != 0) IERC20(currency).safeTransferFrom(_msgSender(), address(this), amount);

        if (topBid.amount != 0) IERC20(topBid.currency).safeTransfer(topBid.bidder, topBid.amount);

        bids.add(lotKey, _msgSender(), amount, currency);

        emit OfferAccepted(++offersSold, lotKey, _msgSender(), amount, block.timestamp);
    }

    function isAvailable(uint256 lotKey, bytes32[] calldata proof) internal view returns (bool) {
        return MerkleProof.verify(proof, lotBatchRoot, keccak256(abi.encode(lotKey, getCurrentBatchIndex())));
    }

    function getTopBidByLot(uint256 lotKey) external view returns (Bids.Item memory) {
        return bids.getTopBidByLot(lotKey);
    }

    /**
    @param bidder An address to get the winning lot for.
    @return lotKey The key of the lot that the bidder is the leader of. 0 if the bidder is not a leader.
    @return won Whether the bidder can be outbid. False if the bidder is not a leader.
     */
    function getWinningLot(address bidder) external view returns (uint256 lotKey, bool won) {
        lotKey = bids.getLastBiddedLotOfBidder(bidder);
        Bids.Item memory topBid = bids.getTopBidByLot(lotKey);

        if (bidder != topBid.bidder) return (0, false);

        won =
            topBid.timestamp != 0 &&
            (topBid.timestamp <= block.timestamp - outbiddingTimeframe || getBatchForTimestamp(topBid.timestamp) != getCurrentBatchIndex());
        return (lotKey, won);
    }

    /**
     * @dev Validates the bidding amount.
     *
     * Amount is valid when:
     * - is opening bid and amount is equal to opening bid value
     * - is opening bid and amount is equal to or greater (according to price increment percentage) than starting bid
     * - is next bid and amount is equal starting bid and amount of first bid is equal to zero
     * - is next bid and amount is greater (according to price increment percentage) than previous bid
     */
    function isValidBidAmount(
        uint256 amount,
        uint256 amountToOutbid,
        bool isOpeningBid
    ) internal view returns (bool) {
        if (isOpeningBid) {
            return amount == openingBid || amount >= startingBid;
        }

        if (amountToOutbid == 0) {
            return amount >= startingBid;
        }

        return amount >= (amountToOutbid * (100 + priceIncrementPercentage)) / 100;
    }
}