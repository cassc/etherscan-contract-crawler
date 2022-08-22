// SPDX-License-Identifier: GPL-3.0

/// @title The Nouns DAO auction house

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

// LICENSE
// NounsAuctionHouse.sol is a modified version of Nouns' NounsAuctionHouse.sol:
// https://github.com/nounsDAO/nouns-monorepo/blob/master/packages/nouns-contracts/contracts/NounsAuctionHouse.sol
//
// AuctionHouse.sol source code Copyright Zora licensed under the GPL-3.0 license.
// With modifications by Nounders DAO.

pragma solidity ^0.8.13;

import { ReentrancyGuardUpgradeable } from '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { INounsAuctionHouse } from './interfaces/INounsAuctionHouse.sol';
import { INounsToken } from './interfaces/INounsToken.sol';
import { IWETH } from './interfaces/IWETH.sol';
import { MerkleProof } from '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import "@openzeppelin/contracts/utils/Counters.sol";

contract NounsAuctionHouse is INounsAuctionHouse, ReentrancyGuardUpgradeable {    
    using Counters for Counters.Counter;
    Counters.Counter internal _collectionIds;

    // The address of the WETH contract
    address public weth;

    // The minimum amount of time left in an auction after a new bid is created
    uint256 public timeBuffer;

    // The minimum percentage difference between the last bid amount and the current bid
    uint8 public minBidIncrementPercentage;

    // Mapping from collectionID to NounsToken contract
    mapping(uint256 => INounsToken) public nouns;

    // Mapping from collectionID to reserve price
    mapping(uint256 => uint256) public reservePrices;

    // Mapping from collectionID to duration
    mapping(uint256 => uint256) public durations;

    // Mapping from collectionID to active auction
    mapping(uint256 => INounsAuctionHouse.Auction) public auctions;

    // Mapping from token ID to creator
    mapping(uint256 => address) public creatorAddresses;

    // Mapping from token ID to paused status
    mapping(uint256 => bool) public isPaused;

    // Mapping from token ID to collection size
    mapping(uint256 => uint256) public collectionSizes;

    address owner;
    uint256 primaryTakeRatePerHundred;

    /**
     * @notice Require that the sender is the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, 'Sender is not the owner');
        _;
    }

    /**
     * @notice Require that the sender is the owner.
     */
    modifier ownerOrCreator(uint256 collectionId) {
        require(msg.sender == owner || msg.sender == creatorAddresses[collectionId], 'Sender is not the owner or creator');
        _;
    }

    /**
     * @notice Initialize the auction house and base contracts,
     * populate configuration values, and pause the contract.
     * @dev This function can only be called once.
     */
    function initialize(
        address _weth,
        uint256 _timeBuffer,
        uint8 _minBidIncrementPercentage,
        address initialOwner,
        uint256 primaryTakeRate
    ) external initializer {
        __ReentrancyGuard_init();

        weth = _weth;
        timeBuffer = _timeBuffer;
        minBidIncrementPercentage = _minBidIncrementPercentage;
        owner = initialOwner;
        primaryTakeRatePerHundred = primaryTakeRate;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function initializeNewNounToken(
        INounsToken noun,
        uint256 reservePrice,
        uint256 duration,
        address creatorAddress,
        uint256 collectionSize,
        bytes32 merkleRoot
    ) external {
        require(owner == msg.sender || creatorAddress == msg.sender);
        uint256 nextCollectionId = _collectionIds.current();
        _collectionIds.increment();
        creatorAddresses[nextCollectionId] = creatorAddress;
        reservePrices[nextCollectionId] = reservePrice;
        durations[nextCollectionId] = duration;
        nouns[nextCollectionId] = noun;
        collectionSizes[nextCollectionId] = collectionSize;
        isPaused[nextCollectionId] = true;
        noun.setMerkleRoot(merkleRoot);

        emit NewNounTokenInitialized(
            address(noun),
            nextCollectionId,
            reservePrice,
            duration,
            creatorAddress,
            collectionSize,
            merkleRoot
        );
    }

    /**
     * @notice Settle the current auction, mint a new Noun, and put it up for auction.
     */
    function settleCurrentAndCreateNewAuction(uint256 collectionId, string memory tokenCID, bytes32[] calldata merkleProof) external nonReentrant {
        require(!isPaused[collectionId]);
        INounsAuctionHouse.Auction memory _auction = auctions[collectionId];
        bytes32 leaf = keccak256(abi.encodePacked(tokenCID));
        require(MerkleProof.verify(merkleProof, nouns[collectionId].merkleRoot(), leaf), "Invalid proof");
        require(!nouns[collectionId].isExistingTokenCID(tokenCID), "Repeat URI");
        require(_auction.nounId < collectionSizes[collectionId] - 1, "Collection is finished");
        _settleAuction(collectionId);
        _createAuction(collectionId, tokenCID, merkleProof);
    }

    /**
     * @notice Settle the current auction.
     * @dev This function can only be called when the contract is paused.
     */
    function settleAuction(uint256 collectionId) external override nonReentrant {
        INounsAuctionHouse.Auction memory _auction = auctions[collectionId];
        require(isPaused[collectionId] || _auction.nounId == collectionSizes[collectionId] - 1);
        _settleAuction(collectionId);
    }

    /**
     * @notice Create a bid for a Noun, with a given amount.
     * @dev This contract only accepts payment in ETH.
     */
    function createBid(uint256 collectionId, uint256 nounId) external payable override nonReentrant {
        INounsAuctionHouse.Auction memory _auction = auctions[collectionId];

        require(_auction.nounId == nounId, 'Noun not up for auction');
        require(block.timestamp < _auction.endTime, 'Auction expired');
        require(msg.value >= reservePrices[collectionId], 'Must send at least reservePrice');
        require(
            msg.value >= _auction.amount + ((_auction.amount * minBidIncrementPercentage) / 100),
            'Must send more than last bid by minBidIncrementPercentage amount'
        );

        address payable lastBidder = _auction.bidder;

        // Refund the last bidder, if applicable
        if (lastBidder != address(0)) {
            _safeTransferETHWithFallback(lastBidder, _auction.amount);
        }

        auctions[collectionId].amount = msg.value;
        auctions[collectionId].bidder = payable(msg.sender);

        // Extend the auction if the bid was received within `timeBuffer` of the auction end time
        bool extended = _auction.endTime - block.timestamp < timeBuffer;
        if (extended) {
            auctions[collectionId].endTime = _auction.endTime = block.timestamp + timeBuffer;
        }

        emit AuctionBid(collectionId, _auction.nounId, msg.sender, msg.value, extended);

        if (extended) {
            emit AuctionExtended(collectionId, _auction.nounId, _auction.endTime);
        }
    }

    /**
     * @notice Pause the Nouns auction house.
     * @dev This function can only be called by the owner when the
     * contract is unpaused. While no new auctions can be started when paused,
     * anyone can settle an ongoing auction.
     */
    function pause(uint256 collectionId) external override ownerOrCreator(collectionId) {
        isPaused[collectionId] = true;
    }

    /**
     * @notice Unpause the Nouns auction house.
     * @dev This function can only be called by the owner when the
     * contract is paused. If required, this function will start a new auction.
     */
    function unpause(uint256 collectionId, string memory tokenCID, bytes32[] calldata merkleProof) external ownerOrCreator(collectionId) {
        isPaused[collectionId] = false;

        if (auctions[collectionId].startTime == 0 || auctions[collectionId].settled) {
            bytes32 leaf = keccak256(abi.encodePacked(tokenCID));
            INounsAuctionHouse.Auction memory _auction = auctions[collectionId];
            require(MerkleProof.verify(merkleProof, nouns[collectionId].merkleRoot(), leaf), "Invalid proof");
            require(!nouns[collectionId].isExistingTokenCID(tokenCID), "Repeat URI");
            require(_auction.nounId <= collectionSizes[collectionId] - 1, "Collection is finished");
            _createAuction(collectionId, tokenCID, merkleProof);
        }
    }

    /**
     * @notice Set the auction time buffer.
     * @dev Only callable by the owner.
     */
    function setTimeBuffer(uint256 _timeBuffer) external override onlyOwner {
        timeBuffer = _timeBuffer;

        emit AuctionTimeBufferUpdated(_timeBuffer);
    }

    /**
     * @notice Set the auction reserve price.
     * @dev Only callable by the owner.
     */
    function setReservePrice(uint256 collectionId, uint256 _reservePrice) external override ownerOrCreator(collectionId) {
        reservePrices[collectionId] = _reservePrice;

        emit AuctionReservePriceUpdated(collectionId, _reservePrice);
    }

    function setPrimaryTakeRate(uint256 newPrimaryTakeRate) external onlyOwner {
        primaryTakeRatePerHundred = newPrimaryTakeRate;
    }

    /**
     * @notice Set the auction minimum bid increment percentage.
     * @dev Only callable by the owner.
     */
    function setMinBidIncrementPercentage(uint8 _minBidIncrementPercentage) external override onlyOwner {
        minBidIncrementPercentage = _minBidIncrementPercentage;

        emit AuctionMinBidIncrementPercentageUpdated(_minBidIncrementPercentage);
    }

    /**
     * @notice Create an auction.
     * @dev Store the auction details in the `auction` state variable and emit an AuctionCreated event.
     * If the mint reverts, the minter was updated without pausing this contract first. To remedy this,
     * catch the revert and pause this contract.
     */
    function _createAuction(uint256 collectionId, string memory tokenCID, bytes32[] calldata merkleProof) internal {
        INounsAuctionHouse.Auction memory _auction = auctions[collectionId];
        require(_auction.nounId <= collectionSizes[collectionId] - 1, "Collection is finished");

        try nouns[collectionId].mint(tokenCID, merkleProof) returns (uint256 nounId) {
            uint256 startTime = block.timestamp;
            uint256 endTime = startTime + durations[collectionId];

            auctions[collectionId] = Auction({
                nounId: nounId,
                amount: 0,
                startTime: startTime,
                endTime: endTime,
                bidder: payable(0),
                settled: false
            });

            emit AuctionCreated(collectionId, nounId, startTime, endTime);
        } catch Error(string memory) {
            isPaused[collectionId] = true;
        }
    }

    /**
     * @notice Settle an auction, finalizing the bid and paying out to the owner.
     * @dev If there are no bids, the Noun is burned.
     */
    function _settleAuction(uint256 collectionId) internal {
        INounsAuctionHouse.Auction memory _auction = auctions[collectionId];

        require(_auction.startTime != 0, "Auction hasn't begun");
        require(!_auction.settled, 'Auction has already been settled');
        require(block.timestamp >= _auction.endTime, "Auction hasn't completed");

        auctions[collectionId].settled = true;

        if (_auction.bidder == address(0)) {
            nouns[collectionId].burn(_auction.nounId);
        } else {
            nouns[collectionId].transferFrom(address(this), _auction.bidder, _auction.nounId);
        }

        // Need to pay us the take rate
        if (_auction.amount > 0) {
            uint256 marketPayout = _auction.amount * primaryTakeRatePerHundred / 100;
            _safeTransferETHWithFallback(owner, marketPayout);
            _safeTransferETHWithFallback(creatorAddresses[collectionId], _auction.amount - marketPayout);
        }

        emit AuctionSettled(collectionId, _auction.nounId, _auction.bidder, _auction.amount);
    }

    /**
     * @notice Transfer ETH. If the ETH transfer fails, wrap the ETH and try send it as WETH.
     */
    function _safeTransferETHWithFallback(address to, uint256 amount) internal {
        if (!_safeTransferETH(to, amount)) {
            IWETH(weth).deposit{ value: amount }();
            IERC20(weth).transfer(to, amount);
        }
    }

    /**
     * @notice Transfer ETH and return the success status.
     * @dev This function only forwards 30,000 gas to the callee.
     */
    function _safeTransferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{ value: value, gas: 30_000 }(new bytes(0));
        return success;
    }
}