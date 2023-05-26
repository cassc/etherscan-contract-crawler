// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/// @title Auctions for Checks Elements
/// @author Visualize Value
contract ElementsAuctions is Ownable {
    address constant private VV = 0xc8f8e2F59Dd95fF67c3d39109ecA2e2A017D4c8a;
    uint64 constant private BID_STARTING_PRICE = 0.0044 ether; // 8 USD
    uint16 constant private BID_BASIS_INCREASE = 690;         // 6.9% min increase
    uint64 constant private BID_GRACE_PERIOD = 15 minutes;   // bid extension time

    /// @notice The Elements token contract
    address public elements;

    /// @notice All auctions handled by this contract identified by
    mapping (uint256 => Auction) public auctions;

    /// @dev When the automatic refunds of previous bids fail, they are stored in here.
    mapping(address => uint256) private _withdrawableBalances;

    /// @dev Stores all the data we need for auctions
    struct Auction {
        address latestBidder;   // Winning bidder
        uint128 latestBid;      // Current minimum bid for the auction
        uint64 endTime;         // Current end time of the auction
        uint8 tokenId;          // Element token ID auctioned in this auction
        uint8 edition;          // Complete (0), Compound (1), Composite (2), Isolate (3), Order (4), Alpha (5)
        bool settled;           // Whether the auction is settled
    }

    /// @dev Emitted when a new bid is entered
    event Bid(uint256 indexed auction, uint256 indexed amount, address indexed from);

    /// @dev Emitted when a new bid is entered within the BID_GRACE_PERIOD
    event AuctionExtended(uint256 indexed auctionId, uint256 indexed endTime);

    /// @dev Initializes the contract
    constructor(
        address elements_,
        uint64 startTime,
        uint8[] memory completeIds,
        uint8[] memory compoundIds,
        uint8[] memory compositeIds,
        uint8[] memory isolateIds,
        uint8[] memory orderIds,
        uint8[] memory alphaIds
    ) {
        elements = elements_;
        uint64 endTime = startTime + 24 hours;

        // Set up auctions for each edition bracket (0-5)
        for (uint8 edition = 0; edition < 6; edition++) {
            uint64 auctionEndTime = endTime + edition * 1 hours;
            uint8[] memory tokenIds =
                  edition == 0 ? completeIds
                : edition == 1 ? compoundIds
                : edition == 2 ? compositeIds
                : edition == 3 ? isolateIds
                : edition == 4 ? orderIds
                               : alphaIds;

            _setupEditionAuctions(edition, tokenIds, auctionEndTime);
        }
    }

    /// @notice Fetch multiple auctions at once
    /// @param auctionIds The auction IDs to fetch
    function getAuctions(uint256[] calldata auctionIds) external view returns (Auction[] memory) {
        Auction[] memory auctions_ = new Auction[](auctionIds.length);

        for (uint256 i = 0; i < auctionIds.length; i++) {
            auctions_[i] = auctions[auctionIds[i]];
        }

        return auctions_;
    }

    /// @notice Create a new bid for an auction
    /// @param auctionId The ID of the auction to bid on (0-5)
    function bid(uint256 auctionId) external payable {
        Auction storage auction = auctions[auctionId];
        require(auction.endTime - 24 hours < block.timestamp, "Auction not started");
        require(auction.endTime > block.timestamp, "Auction closed");
        require(msg.value >= _minimumBid(auction), "Min bid not met");

        // Memorize the previous bid to pay back
        uint128 previousBid = auction.latestBid;
        address previousBidder = auction.latestBidder;

        // Add new bid
        auction.latestBidder = msg.sender;
        auction.latestBid = uint128(msg.value);
        emit Bid(auctionId, auction.latestBid, msg.sender);

        // Pay back previous bidder
        if (previousBid > 0) {
            if (!payable(previousBidder).send(previousBid)) {
                _withdrawableBalances[previousBidder] += previousBid;
            }
        }

        // Maybe extend auction
        _updateAuctionEndTime(auction);
    }

    /// @notice Get the current minimum bid for an auction
    /// @param auctionId The ID of the auction to bid on
    function minimumBid (uint256 auctionId) external view returns (uint256) {
        return _minimumBid(auctions[auctionId]);
    }

    /// @notice Settle an auction (only available to the contract owner)
    /// @param auctionIds The ID of the auction to settle (0-5)
    function settleAuctions(
        uint256[] calldata auctionIds
    ) external onlyOwner {
        uint256 proceeds = 0;

        ERC721 elementsToken = ERC721(elements);

        for (uint256 i = 0; i < auctionIds.length; i++) {
            Auction storage auction = auctions[auctionIds[i]];
            require(auction.endTime < block.timestamp, "Auction still running");
            require(! auction.settled, "Auction already settled");

            // Add the bid to our proceeds
            proceeds += auction.latestBid;

            // Send the token to the winner
            elementsToken.transferFrom(
                VV,
                auction.latestBidder,
                auction.tokenId
            );

            // Mark the auction as settled
            auction.settled = true;
        }

        // Withdraw auction proceeds
        payable(msg.sender).transfer(proceeds);
    }

    /// @notice Allow the contract owner to postpone auctions as long as it has not started
    /// @param tokenIds All auctions to delay
    /// @param newStartTime The new start time of the auction
    function postponeAuctions(uint8[] calldata tokenIds, uint64 newStartTime) external onlyOwner {
        uint64 newEnd = newStartTime + 24 hours;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint8 key = tokenIds[i];

            Auction storage auction = auctions[key];
            auction.endTime = newEnd;
        }
    }

    /// @notice Withdraw balance for invalid bids that failed to auto-refund.
    function withdrawBalance() external {
        uint256 amount = _withdrawableBalances[msg.sender];
        require(amount > 0, "No balance to withdraw.");

        // Set balance to prevent reentracy
        _withdrawableBalances[msg.sender] = 0;
        if (!payable(msg.sender).send(amount)) {
            _withdrawableBalances[msg.sender] = amount;
        }
    }

    /// @notice Allows the owner to retreive lost funds stored in the contract after one week.
    function withdraw() external onlyOwner {
        require(block.timestamp > auctions[1].endTime + 7 days, "Force withdraw not available");

        payable(owner()).transfer(address(this).balance);
    }

    /// @dev Returns the current new minimum bid of an auction
    function _minimumBid (Auction storage auction) internal view returns (uint256) {
        return auction.latestBid + auction.latestBid * BID_BASIS_INCREASE / 10_000;
    }

    /// @dev Extends the end time of an auction if we are within the grace period.
    function _updateAuctionEndTime(Auction storage auction) internal {
        uint256 gracePeriodStart = auction.endTime - BID_GRACE_PERIOD;
        uint256 _now = block.timestamp;
        if (_now > gracePeriodStart) {
            auction.endTime = uint64(_now + BID_GRACE_PERIOD);

            emit AuctionExtended(auction.tokenId, auction.endTime);
        }
    }

    /// @dev Initializes auctions for an edition
    function _setupEditionAuctions (uint8 edition, uint8[] memory tokenIds, uint64 endTime) internal {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint8 key = tokenIds[i];

            Auction storage auction = auctions[key];

            auction.edition = edition;
            auction.tokenId = key;
            auction.endTime = endTime;
            auction.settled = false;
        }
    }
}