// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./SkateboardTicket.sol";

error AuctionSettled();
error AuctionNotInitialized();
error AuctionNotLive();
error ReservePriceNotMet();
error IncrementalPriceNotMet();
error BidsNotSorted();
error NonExistentBid();
error AuctionStillLive();
error WithdrawFailed();
error BidIncrementTooLow();
error NotEOA();

contract AuctionHouse is Ownable, ReentrancyGuard {
    struct Bid {
        address bidder;
        uint192 amount;
        uint64 bidTime;
    }

    struct BidIndex {
        uint8 index;
        bool isSet;
    }

    event NewBid(address bidder, uint256 value);
    event BidIncreased(address bidder, uint256 oldValue, uint256 increment);
    event AuctionExtended();

    // The max number of top bids the auction will accept
    uint256 public constant MAX_NUM_BIDS = 8;

    // The token contract to mint from
    SkateboardTicket public st;

    // The minimum amount of time left in an auction after a new bid is created
    uint256 public timeBuffer;

    // The minimum price accepted in an auction
    uint256 public reservePrice;

    // The minimum percentage difference between the last bid amount and the current bid
    uint8 public minBidIncrementPercentage;

    // The minimum amount a user needs to submit for a stacked bid
    uint256 public minStackedBidIncrement;

    // The start time of the auction
    uint256 public startTime;

    // The end time of the auction
    uint256 public endTime;

    // Whether or not the auction has settled.
    bool public auctionSettled;

    // The current highest bids made in the auction
    Bid[MAX_NUM_BIDS] public activeBids;

    // The mapping between an address and its active bid. The isSet flag differentiates the default
    // uint value 0 from an actual 0 value.
    mapping(address => BidIndex) public bidIndexes;

    constructor(
        SkateboardTicket _st,
        uint256 _timeBuffer,
        uint256 _reservePrice,
        uint8 _minBidIncrementPercentage,
        uint256 _minStackedBidIncrement,
        uint256 _startTime,
        uint256 _endTime
    ) {
        st = _st;
        timeBuffer = _timeBuffer;
        reservePrice = _reservePrice;
        minBidIncrementPercentage = _minBidIncrementPercentage;
        minStackedBidIncrement = _minStackedBidIncrement;
        startTime = _startTime;
        endTime = _endTime;
    }

    modifier onlyEOA() {
        if (tx.origin != msg.sender) {
            revert NotEOA();
        }
        _;
    }

    /**
     * @notice Handle users' bids
     * @dev Bids must be made while the auction is live. Bids must meet a minimum reserve price.
     *
     * The first 8 bids made will be accepted as valid. Subsequent bids must be a percentage
     * higher than the lowest of the 8 active bids. When a low bid is replaced, the ETH will
     * be refunded back to the original bidder.
     *
     * If a valid bid comes in within the last `timeBuffer` seconds, the auction will be extended
     * for another `timeBuffer` seconds. This will continue until no new active bids come in.
     *
     * If a wallet makes a bid while it still has an active bid, the second bid will
     * stack on top of the first bid. If the second bid doesn't meet the `minStackedBidIncrement`
     * threshold, an error will be thrown. A wallet will only have one active bid at at time.
     */
    function bid() public payable nonReentrant onlyEOA {
        if (auctionSettled) {
            revert AuctionSettled();
        }
        if (startTime == 0 || endTime == 0) {
            revert AuctionNotInitialized();
        }
        if (block.timestamp < startTime || block.timestamp > endTime) {
            revert AuctionNotLive();
        }

        BidIndex memory existingIndex = bidIndexes[msg.sender];
        if (existingIndex.isSet) {
            // Case when the user already has an active bid
            if (msg.value < minStackedBidIncrement || msg.value == 0) {
                revert BidIncrementTooLow();
            }

            uint192 oldValue = activeBids[existingIndex.index].amount;
            unchecked {
                activeBids[existingIndex.index].amount =
                    oldValue +
                    uint192(msg.value);
            }
            activeBids[existingIndex.index].bidTime = uint64(block.timestamp);

            emit BidIncreased(msg.sender, oldValue, msg.value);
        } else {
            if (msg.value < reservePrice || msg.value == 0) {
                revert ReservePriceNotMet();
            }

            uint8 lowestBidIndex = getBidIndexToUpdate();
            uint256 lowestBidAmount = activeBids[lowestBidIndex].amount;
            address lowestBidder = activeBids[lowestBidIndex].bidder;

            unchecked {
                if (
                    msg.value <
                    lowestBidAmount +
                        (lowestBidAmount * minBidIncrementPercentage) /
                        100
                ) {
                    revert IncrementalPriceNotMet();
                }
            }

            // Refund lowest bidder and remove bidIndexes entry
            if (lowestBidder != address(0)) {
                delete bidIndexes[lowestBidder];
                _transferETH(lowestBidder, lowestBidAmount);
            }

            activeBids[lowestBidIndex] = Bid({
                bidder: msg.sender,
                amount: uint192(msg.value),
                bidTime: uint64(block.timestamp)
            });

            bidIndexes[msg.sender] = BidIndex({
                index: lowestBidIndex,
                isSet: true
            });

            emit NewBid(msg.sender, msg.value);
        }

        // Extend the auction if the bid was received within `timeBuffer` of the auction end time
        if (endTime - block.timestamp < timeBuffer) {
            unchecked {
                endTime = block.timestamp + timeBuffer;
            }
            emit AuctionExtended();
        }
    }

    /**
     * @notice Gets the index of the entry in activeBids to update
     * @dev The index to return will be decided by the following rules:
     * If there are less than MAX_NUM_BIDS bids, the index of the first empty slot is returned.
     * If there are MAX_NUM_BIDS or more bids, the index of the lowest value bid is returned. If
     * there is a tie, the most recent bid with the low amount will be returned. If there is a tie
     * among bidTimes, the highest index is chosen.
     */
    function getBidIndexToUpdate() public view returns (uint8) {
        uint256 minAmount = activeBids[0].amount;
        // If the first value is 0 then we can assume that no bids have been submitted
        if (minAmount == 0) {
            return 0;
        }

        uint8 minIndex = 0;
        uint64 minBidTime = activeBids[0].bidTime;

        for (uint8 i = 1; i < MAX_NUM_BIDS; ) {
            uint256 bidAmount = activeBids[i].amount;
            uint64 bidTime = activeBids[i].bidTime;

            // A zero bidAmount means the slot is empty because we enforce non-zero bid amounts
            if (bidAmount == 0) {
                return i;
            } else if (
                bidAmount < minAmount ||
                (bidAmount == minAmount && bidTime >= minBidTime)
            ) {
                minAmount = bidAmount;
                minIndex = i;
                minBidTime = bidTime;
            }

            unchecked {
                ++i;
            }
        }

        return minIndex;
    }

    /**
     * @notice Get all active bids.
     * @dev Useful for ethers client to get the entire array at once.
     */
    function getAllActiveBids()
        external
        view
        returns (Bid[MAX_NUM_BIDS] memory)
    {
        return activeBids;
    }

    /**
     * @notice Settles the auction and mints a skateboard ticket NFT to each winner.
     * @dev Bids will be sorted in descending order off-chain due to constraints with
     * sorting structs on-chain via a field on the struct, however we will validate the
     * input on-chain before minting the NFTs. The input bids must be in descending order
     * by amount and all input bids must correspond to a bid in the `activeBids` mapping.
     * @dev Duplicate bids can be passed in to circumvent the validation logic. We are ok
     * with this loophole since this function is ownerOnly.
     * @dev Settlement is only possible once the auction is over.
     */
    function settleAuction(Bid[MAX_NUM_BIDS] calldata sortedBids)
        external
        onlyOwner
        nonReentrant
    {
        if (block.timestamp <= endTime) {
            revert AuctionStillLive();
        }
        if (auctionSettled) {
            revert AuctionSettled();
        }

        // Validate the input bids
        for (uint256 i = 0; i < MAX_NUM_BIDS; ) {
            Bid memory inputBid = sortedBids[i];
            BidIndex memory bidIndex = bidIndexes[inputBid.bidder];
            if (
                !bidIndex.isSet ||
                activeBids[bidIndex.index].bidder != inputBid.bidder ||
                activeBids[bidIndex.index].amount != inputBid.amount ||
                activeBids[bidIndex.index].bidTime != inputBid.bidTime
            ) {
                revert NonExistentBid();
            }

            // The zero-th index has nothing to compare against
            if (i != 0) {
                Bid memory prevBid = sortedBids[i - 1];
                if (inputBid.amount > prevBid.amount) {
                    revert BidsNotSorted();
                }
            }

            unchecked {
                ++i;
            }
        }

        // Mint tickets to auction winners
        for (uint256 i; i < MAX_NUM_BIDS; ) {
            st.mint(sortedBids[i].bidder);
            unchecked {
                ++i;
            }
        }

        auctionSettled = true;
    }

    /**
     * @notice Transfers ETH to a specified address.
     * @dev This function can only be called internally.
     */
    function _transferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{value: value, gas: 30000}(new bytes(0));
        return success;
    }

    /**
     * @notice Sets the start and end time of the auction.
     * @dev Only callable by the owner.
     */
    function setAuctionTimes(uint256 _startTime, uint256 _endTime)
        external
        onlyOwner
    {
        startTime = _startTime;
        endTime = _endTime;
    }

    /**
     * @notice Set the auction time buffer.
     * @dev Only callable by the owner.
     */
    function setTimeBuffer(uint256 _timeBuffer) external onlyOwner {
        timeBuffer = _timeBuffer;
    }

    /**
     * @notice Set the auction reserve price.
     * @dev Only callable by the owner.
     */
    function setReservePrice(uint256 _reservePrice) external onlyOwner {
        reservePrice = _reservePrice;
    }

    /**
     * @notice Set the auction minimum bid increment percentage.
     * @dev Only callable by the owner.
     */
    function setMinBidIncrementPercentage(uint8 _minBidIncrementPercentage)
        external
        onlyOwner
    {
        minBidIncrementPercentage = _minBidIncrementPercentage;
    }

    /**
     * @notice Set the auction replacing bid buffer amount.
     * @dev Only callable by the owner.
     */
    function setMinReplacementIncrease(uint256 _minStackedBidIncrement)
        external
        onlyOwner
    {
        minStackedBidIncrement = _minStackedBidIncrement;
    }

    /**
     * @notice Withdraws the contract value to the owner
     */
    function withdraw() external onlyOwner {
        bool success = _transferETH(msg.sender, address(this).balance);
        if (!success) {
            revert WithdrawFailed();
        }
    }
}