// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./TwentySevenYearScapes.sol";

/*
            @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
              |     |     |     |     |     |     [email protected]@
              |     |     |     |     |     |     [email protected]@
              |     |     |     |     |     |     [email protected]@
              |     |     |     |     |     |     [email protected]@
            @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
            @@-     |     ||    |    ||     |     |
            @@-     |     ||    |    ||     |     |
            @@-     |     ||    |    ||     |     |
            @@-     |     ||    |    ||     |     |
@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]
*/
contract GalleryTwentySeven is Ownable, ReentrancyGuard {
    // Scape collection contracts
    address private _scapes;
    address private _twentySevenYearScapes;

    /// @dev The signer for new auctions.
    address private _signer;

    /// @dev The minimum value of an auction.
    uint128 private _startingPrice;

    /// @dev The minimum basis points increase per bid.
    uint64 private _bidBasisIncrease;

    /// @dev Minimum auction runtime in seconds after new bids.
    uint64 private _biddingGracePeriod;

    /// @dev The auction for each Scape tokenID.
    mapping(uint256 => Auction) private _auctions;

    /// @dev When the automatic refunds of previous bids fail, they are stored in here.
    mapping(address => uint256) private _failedBidBalances;

    struct Auction {
        address latestBidder;
        uint128 latestBid;
        uint64 endTimestamp;
        bool rewardsClaimed;
        bool settled;
    }

    /// @dev Emitted when a new bid is entered.
    event Bid(
        uint256 indexed scapeId,
        uint256 indexed bid,
        address indexed from,
        string message
    );

    /// @dev Emitted when a new bid is entered within the _biddingGracePeriod.
    event AuctionExtended(
        uint256 indexed scapeId,
        uint256 indexed endTimestamp
    );

    /// @dev Initialize the Gallery contract
    constructor(
        address scapes,
        address twentySevenYearScapes,
        uint128 startingPrice,
        uint64 bidBasisIncrease,
        uint64 biddingGracePeriod
    ) {
        _scapes = scapes;
        _twentySevenYearScapes = twentySevenYearScapes;
        _startingPrice = startingPrice;
        _bidBasisIncrease = bidBasisIncrease;
        _biddingGracePeriod = biddingGracePeriod;
        _signer = owner();
    }

    /// @dev Get an auction for a specific Scape tokenID
    function getAuction(uint256 scapeId)
        public
        view
        returns (
            address latestBidder,
            uint128 latestBid,
            uint64 endTimestamp,
            bool settled,
            bool rewardsClaimed
        )
    {
        Auction memory auction = _auctions[scapeId];

        return (
            auction.latestBidder,
            auction.latestBid,
            auction.endTimestamp,
            auction.settled,
            auction.rewardsClaimed
        );
    }

    function currentStartingPrice() external view returns (uint128) {
        return _startingPrice;
    }

    function currentBidBasisIncrease() external view returns (uint64) {
        return _bidBasisIncrease;
    }

    function currentBiddingGracePeriod() external view returns (uint64) {
        return _biddingGracePeriod;
    }

    /// @dev The minimum value of the next bid for an auction.
    function currentBidPrice(uint256 scapeId) external view returns (uint128) {
        return _currentBidPrice(_auctions[scapeId]);
    }

    /// @dev The first bid to initialize an auction
    /// @param scapeId The tokenId of the Scape of the day
    /// @param endTimestamp The default end time of the auction
    /// @param signature The signature to verify the above arguments
    /// @param message The bid message that inspires Yotukito
    function initializeAuction(
        uint256 scapeId,
        uint64 endTimestamp,
        bytes memory signature,
        string memory message
    ) external payable {
        require(
            _auctions[scapeId].endTimestamp == 0,
            "Auction has already started."
        );
        require(msg.value >= _startingPrice, "Auction starting price not met.");
        require(endTimestamp >= uint64(block.timestamp), "Auction has ended.");

        // Verify this data was signed by punkscape
        bytes32 signedData = ECDSA.toEthSignedMessageHash(
            keccak256(abi.encodePacked(scapeId, endTimestamp))
        );
        require(
            ECDSA.recover(signedData, signature) == _signer,
            "Auction data not signed."
        );

        _auctions[scapeId] = Auction(
            _msgSender(),
            uint128(msg.value),
            endTimestamp,
            false,
            false
        );
        _maybeExtendTime(scapeId, _auctions[scapeId]);

        emit Bid(scapeId, msg.value, _msgSender(), message);
    }

    /// @dev Secondary bids
    /// @param scapeId The tokenId of the Scape to bid on
    /// @param message The bid message that inspires Yotukito
    function bid(uint256 scapeId, string memory message)
        external
        payable
        nonReentrant
    {
        Auction storage auction = _auctions[scapeId];
        uint256 bidValue = msg.value;
        address bidder = msg.sender;

        require(
            bidValue >= _currentBidPrice(auction),
            "Minimum bid value not met."
        );
        require(
            block.timestamp <= auction.endTimestamp,
            "Auction is not active."
        );

        // Pay back previous bidder
        if (_hasBid(auction)) {
            if (!payable(auction.latestBidder).send(auction.latestBid)) {
                _failedBidBalances[auction.latestBidder] += auction.latestBid;
            }
        }

        _maybeExtendTime(scapeId, auction);

        // Store the bid
        auction.latestBid = uint128(bidValue);
        auction.latestBidder = bidder;

        emit Bid(scapeId, bidValue, bidder, message);
    }

    /// @dev Mints a Twenty Seven Year Scape (27YS).
    /// @param scapeId The tokenId of the Scape for which to claim the 27YS
    /// @param tokenId The tokenId of the 27YS
    /// @param cid The IPFS content identifyer of the metadata of this token
    /// @param signature The signature that verifies the authenticity of the above arguments
    function claim(
        uint256 scapeId,
        uint256 tokenId,
        string memory cid,
        bytes memory signature
    ) external {
        Auction storage auction = _auctions[scapeId];
        require(!auction.settled, "Auction already settled");

        // Verify this data was signed by punkscape
        bytes32 message = ECDSA.toEthSignedMessageHash(
            keccak256(abi.encodePacked(scapeId, tokenId, cid))
        );
        require(
            ECDSA.recover(message, signature) == _signer,
            "Claim data not signed."
        );

        address claimableBy = _hasBid(auction)
            ? auction.latestBidder
            : ERC721(_scapes).ownerOf(scapeId);
        require(_msgSender() == claimableBy, "Not allowed to claim.");

        TwentySevenYearScapes(_twentySevenYearScapes).mint(
            claimableBy,
            tokenId,
            cid
        );

        // Reserve 50% of the auction reward for the Scape owner
        uint256 ownerShare = auction.latestBid / 2;
        payable(owner()).transfer(auction.latestBid - ownerShare);

        // End the auction
        auction.settled = true;
    }

    /// @dev Claims the rewards of previous auctions.
    /// @param scapeIDs The tokenIDs of all Scapes for which to claim rewards.
    function withdraw(uint256[] memory scapeIDs) external {
        uint128 total = 0;

        for (uint256 index = 0; index < scapeIDs.length; index++) {
            uint256 id = scapeIDs[index];
            Auction storage auction = _auctions[id];

            // The rewards must not be claimed yet and the auction must be complete
            require(
                auction.rewardsClaimed == false,
                "Auction rewards already claimed"
            );
            require(
                auction.endTimestamp < block.timestamp &&
                    auction.endTimestamp > 0,
                "Auction not complete"
            );

            // Holders can claim rewards within one year after an auction ends
            uint64 oneYear = 31536000;
            if (auction.endTimestamp + oneYear > block.timestamp) {
                address scapeOwner = ERC721(_scapes).ownerOf(id);
                require(scapeOwner == _msgSender(), "Not eligible for reward");
            } else {
                require(_msgSender() == owner(), "Not eligible for reward");
            }

            // Mark the auction rewards as already claimed to prevent multiple claims
            auction.rewardsClaimed = true;

            // 50% of total rewards
            total += auction.latestBid / 2;
        }

        // Pay out the rewards
        payable(_msgSender()).transfer(total);
    }

    /// @dev Extends the end time of an auction if we are within the grace period.
    function _maybeExtendTime(uint256 scapeId, Auction storage auction)
        internal
    {
        uint64 gracePeriodStart = auction.endTimestamp - _biddingGracePeriod;
        uint64 _now = uint64(block.timestamp);
        if (_now > gracePeriodStart) {
            auction.endTimestamp = _now + _biddingGracePeriod;

            emit AuctionExtended(scapeId, auction.endTimestamp);
        }
    }

    /// @dev Set the signer address used to verify initializeAuction and claim.
    function setSigner(address signer_) external onlyOwner {
        _signer = signer_;
    }

    /// @dev Set the default auction starting price.
    function setStartingPrice(uint128 startingPrice) external onlyOwner {
        _startingPrice = startingPrice;
    }

    /// @dev Set the minimum percentage increase for bids in an auction.
    function setBidBasisIncrease(uint64 bidBasisIncrease) external onlyOwner {
        _bidBasisIncrease = bidBasisIncrease;
    }

    /// @dev Set ducation of the bidding grace period in seconds.
    function setBiddingGracePeriod(uint64 biddingGracePeriod)
        external
        onlyOwner
    {
        _biddingGracePeriod = biddingGracePeriod;
    }

    /// @dev Whether an auction has an existing bid.
    function _hasBid(Auction memory auction) internal pure returns (bool) {
        return auction.latestBid > 0;
    }

    /// @dev Calculates the minimum price for the next bid.
    function _currentBidPrice(Auction memory auction)
        internal
        view
        returns (uint128)
    {
        if (!_hasBid(auction)) {
            return _startingPrice;
        }

        uint128 percentageIncreasePrice = (auction.latestBid *
            (10000 + _bidBasisIncrease)) / 10000;
        return
            percentageIncreasePrice - auction.latestBid < _startingPrice
                ? auction.latestBid + _startingPrice
                : percentageIncreasePrice;
    }

    /// @dev Get the failed bid balance for an address.
    function getFailedBidBalance(address _address)
        external
        view
        returns (uint256)
    {
        return _failedBidBalances[_address];
    }

    /// @dev Withdraw user balance in case automatic refund in bid failed.
    function withdrawFailedBidBalance() external {
        uint256 amount = _failedBidBalances[msg.sender];
        require(amount > 0, "No balance to withdraw.");
        // Set balance to zero because it could be called again in receive before send returns
        _failedBidBalances[msg.sender] = 0;
        if (!payable(msg.sender).send(amount)) {
            _failedBidBalances[msg.sender] = amount;
        }
    }
}