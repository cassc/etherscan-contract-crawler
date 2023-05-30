// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {IGnarSeeder} from "./GNARSeeder.sol";
import {IGnarDescriptor} from "./GNARDescriptor.sol";

/**
 * @title SkateContract
 */
contract SkateContract is
    ERC721Enumerable,
    Ownable,
    ReentrancyGuardUpgradeable
{
    using Strings for uint256;

    struct Auction {
        // ID for the gnar (ERC721 token ID)
        uint256 gnarId;
        // The current highest bid amount
        uint256 amount;
        // The block number that the auction started
        uint256 startBlock;
        // The time that the auction is scheduled to end
        uint256 endBlock;
        // The address of the current highest bid
        address payable bidder;
        // Skate percentage
        uint8 skatePercent;
        // Dao percentage
        uint8 daoPercent;
        // Whether or not the auction has been settled
        bool settled;
    }

    event AuctionCreated(uint256 indexed gnarId);
    event AuctionBid(
        uint256 indexed gnarId,
        address sender,
        uint256 value,
        uint256 timestamp
    );
    event AuctionSettled(
        uint256 indexed gnarId,
        address winner,
        uint256 amount,
        uint256 timestamp
    );
    event MinBidIncrementPercentageUpdated(uint8 percent);
    event ReservePriceUpdated(uint256 price);

    // The number of blocks an auction lasts
    uint16 public auctionPeriodBlocks = 666;
    // The Gnar token URI descriptor address
    IGnarDescriptor public descriptor;
    // The Gnar token seeder
    IGnarSeeder public seeder;
    // The internal Skate ID tracker
    uint256 public currentGnarId;
    // current Auction info like gnarId,
    Auction public auction;
    // The minimum price accepted in an auction
    uint256 public reservePrice;
    // The minimum percentage difference between the last bid amount and the current bid
    uint8 public minBidIncrementPercentage;
    // The seeds
    mapping(uint256 => IGnarSeeder.Seed) public seeds;
    // paused
    bool public paused = true;
    // skate address
    address public skate;
    // dao address
    address public dao;

    constructor(
        address _skate,
        address _dao,
        address _descriptor,
        address _seeder,
        uint256 _reservePrice,
        uint8 _minBidIncrementPercentage
    ) ERC721("Skate or DAO", "GNAR") {
        require(
            _skate != address(0) &&
                _dao != address(0) &&
                _descriptor != address(0) &&
                _seeder != address(0),
            "ZERO ADDRESS"
        );
        skate = _skate;
        dao = _dao;
        descriptor = IGnarDescriptor(_descriptor);
        seeder = IGnarSeeder(_seeder);
        reservePrice = _reservePrice;
        minBidIncrementPercentage = _minBidIncrementPercentage;
    }

    /**
     * set skate and dao address
     */
    function setSkateDaoAddresses(address _skate, address _dao)
        external
        onlyOwner
    {
        require(_skate != address(0) && _dao != address(0), "ZERO ADDRESS");
        skate = _skate;
        dao = _dao;
    }

    /**
     * Auction start by onwer
     */
    function auctionStart() external onlyOwner {
        require(paused, "Auction already started");
        paused = false;
        _createAuction();
    }

    /**
     * @notice Settle the current auction, mint a new Gnar, and put it up for auction.
     */
    function settleCurrentAndCreateNewAuction() external nonReentrant {
        require(!paused, "Auction is paused");
        _settleAuction();
        _createAuction();
    }

    /**
     * @notice Set the token URI descriptor.
     * @dev Only callable by the owner when not locked.
     */
    function setDescriptor(address _descriptor) external onlyOwner {
        require(_descriptor != address(0), "ZERO ADDRESS");
        descriptor = IGnarDescriptor(_descriptor);
    }

    /**
     * @notice Set the token seeder.
     * @dev Only callable by the owner when not locked.
     */
    function setSeeder(address _seeder) external onlyOwner {
        require(_seeder != address(0), "ZERO ADDRESS");
        seeder = IGnarSeeder(_seeder);
    }

    function mint() internal returns (uint256) {
        IGnarSeeder.Seed memory _seed = seeder.generateSeed(
            currentGnarId,
            descriptor
        );
        uint256 tokenId = currentGnarId;
        _safeMint(msg.sender, tokenId);
        currentGnarId++;
        seeds[tokenId] = _seed;
        return tokenId;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");

        return descriptor.tokenURI(tokenId, seeds[tokenId]);
    }

    /**
     * @notice Create a bid for a Gnar, with a given amount.
     * @dev This contract only accepts payment in ETH.
     */
    function createBid(
        uint256 gnarId,
        uint8 _skatePercent,
        uint8 _daoPercent
    ) external payable nonReentrant {
        Auction memory _auction = auction;

        require(_auction.gnarId == gnarId, "Gnar not up for auction");
        require(
            _skatePercent + _daoPercent == 100,
            "Sum of percents is not 100"
        );
        require(block.number < _auction.endBlock, "Auction expired");
        require(msg.value >= reservePrice, "Must send at least reservePrice");
        require(
            msg.value >=
                _auction.amount +
                    ((_auction.amount * minBidIncrementPercentage) / 100),
            "Must send more than last bid by minBidIncrementPercentage amount"
        );

        address payable lastBidder = _auction.bidder;

        // Refund the last bidder, if applicable
        if (lastBidder != address(0)) {
            require(
                _safeTransferETH(lastBidder, _auction.amount),
                "ETH transfer failed"
            );
        }

        auction.amount = msg.value;
        auction.bidder = payable(msg.sender);
        auction.skatePercent = _skatePercent;
        auction.daoPercent = _daoPercent;

        emit AuctionBid(
            _auction.gnarId,
            msg.sender,
            msg.value,
            block.timestamp
        );
    }

    /**
     * @notice Create an auction.
     * @dev Store the auction details in the `auction` state variable and emit an AuctionCreated event.
     * If the mint reverts, the minter was updated without pausing this contract first. To remedy this,
     * catch the revert and pause this contract.
     */
    function _createAuction() internal {
        uint256 gnarId = mint();
        uint256 startBlock = block.number;
        uint256 endBlock = startBlock + auctionPeriodBlocks;

        auction = Auction({
            gnarId: gnarId,
            amount: 0,
            startBlock: startBlock,
            endBlock: endBlock,
            bidder: payable(0),
            skatePercent: 50,
            daoPercent: 50,
            settled: false
        });

        emit AuctionCreated(gnarId);
    }

    /**
     * @notice Settle an auction, finalizing the bid and paying out to the owner.
     * @dev If there are no bids, the Gnar is burned.
     */
    function _settleAuction() internal {
        Auction memory _auction = auction;
        require(_auction.startBlock != 0, "Auction hasn't begun");
        require(!_auction.settled, "Auction has already been settled");
        require(block.number >= _auction.endBlock, "Auction hasn't completed");

        auction.settled = true;

        if (_auction.bidder == address(0)) {
            burn(_auction.gnarId);
        } else {
            transferFrom(owner(), _auction.bidder, _auction.gnarId);
        }

        if (_auction.amount > 0) {
            require(
                _safeTransferETH(
                    skate,
                    (_auction.amount * _auction.skatePercent) / 100
                ),
                "ETH transfer failed"
            );
            require(
                _safeTransferETH(
                    dao,
                    (_auction.amount * _auction.daoPercent) / 100
                ),
                "ETH transfer failed"
            );
        }

        emit AuctionSettled(
            _auction.gnarId,
            _auction.bidder,
            _auction.amount,
            block.timestamp
        );
    }

    /**
     * @notice Pause the gnar auction house.
     * @dev This function can only be called by the owner when the
     * contract is unpaused. While no new auctions can be started when paused,
     * anyone can settle an ongoing auction.
     */
    function pause() external onlyOwner {
        require(!paused, "Already Paused");
        paused = true;
    }

    /**
     * @notice Unpause the Gnars auction house.
     * @dev This function can only be called by the owner when the
     * contract is paused. If required, this function will start a new auction.
     */
    function unpause() external onlyOwner {
        require(paused, "Already Auction running");
        paused = false;
        if (auction.endBlock < block.number) {
            if (auction.settled) {
                _createAuction();
            } else {
                _settleAuction();
                _createAuction();
            }
        }
    }

    /**
     * @notice Set the auction reserve price.
     * @dev Only callable by the owner.
     */
    function setReservePrice(uint256 _reservePrice) external onlyOwner {
        reservePrice = _reservePrice;
        emit ReservePriceUpdated(_reservePrice);
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
        emit MinBidIncrementPercentageUpdated(_minBidIncrementPercentage);
    }

    /**
     * @notice Burn a gnar.
     */
    function burn(uint256 gnarId) public onlyOwner {
        _burn(gnarId);
    }

    /**
     * @notice Transfer ETH.
     */
    function _safeTransferETH(address to, uint256 amount)
        internal
        returns (bool)
    {
        (bool success, ) = to.call{value: amount, gas: 50_000}(new bytes(0));
        return success;
    }

    function remainBlocks() external view returns (uint256) {
        require(auction.endBlock >= block.number, "No remain blocks!");
        return auction.endBlock - block.number;
    }

    function setAuctionPeriodBlocks(uint16 _auctionPeriodBlocks)
        external
        onlyOwner
    {
        auctionPeriodBlocks = _auctionPeriodBlocks;
    }
}