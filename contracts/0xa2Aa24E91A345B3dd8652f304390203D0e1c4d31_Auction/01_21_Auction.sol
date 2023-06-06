// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import './library/UtilLib.sol';

import '../contracts/interfaces/SDCollateral/IAuction.sol';
import '../contracts/interfaces/IStaderStakePoolManager.sol';

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';

contract Auction is IAuction, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    IStaderConfig public override staderConfig;
    uint256 public override nextLot;
    uint256 public override bidIncrement;
    uint256 public override duration;

    mapping(uint256 => LotItem) public lots;

    uint256 public constant MIN_AUCTION_DURATION = 7200; // 24 hours

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _admin, address _staderConfig) external initializer {
        UtilLib.checkNonZeroAddress(_admin);
        UtilLib.checkNonZeroAddress(_staderConfig);

        __AccessControl_init();
        __ReentrancyGuard_init();

        staderConfig = IStaderConfig(_staderConfig);
        duration = 2 * MIN_AUCTION_DURATION;
        bidIncrement = 5e15;
        nextLot = 1;

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        emit UpdatedStaderConfig(_staderConfig);
        emit AuctionDurationUpdated(duration);
        emit BidIncrementUpdated(bidIncrement);
    }

    function createLot(uint256 _sdAmount) external override {
        lots[nextLot].startBlock = block.number;
        lots[nextLot].endBlock = block.number + duration;
        lots[nextLot].sdAmount = _sdAmount;

        LotItem storage lotItem = lots[nextLot];

        if (!IERC20(staderConfig.getStaderToken()).transferFrom(msg.sender, address(this), _sdAmount)) {
            revert SDTransferFailed();
        }
        emit LotCreated(nextLot, lotItem.sdAmount, lotItem.startBlock, lotItem.endBlock, bidIncrement);
        nextLot++;
    }

    function addBid(uint256 lotId) external payable override {
        // reject payments of 0 ETH
        if (msg.value == 0) revert InSufficientETH();

        LotItem storage lotItem = lots[lotId];
        if (block.number > lotItem.endBlock) revert AuctionEnded();

        uint256 totalUserBid = lotItem.bids[msg.sender] + msg.value;

        if (totalUserBid < lotItem.highestBidAmount + bidIncrement) revert InSufficientBid();

        lotItem.highestBidder = msg.sender;
        lotItem.highestBidAmount = totalUserBid;
        lotItem.bids[msg.sender] = totalUserBid;

        emit BidPlaced(lotId, msg.sender, totalUserBid);
    }

    function claimSD(uint256 lotId) external override {
        LotItem storage lotItem = lots[lotId];
        if (block.number <= lotItem.endBlock) revert AuctionNotEnded();
        if (msg.sender != lotItem.highestBidder) revert notQualified();
        if (lotItem.sdClaimed) revert AlreadyClaimed();

        lotItem.sdClaimed = true;
        if (!IERC20(staderConfig.getStaderToken()).transfer(lotItem.highestBidder, lotItem.sdAmount)) {
            revert SDTransferFailed();
        }
        emit SDClaimed(lotId, lotItem.highestBidder, lotItem.sdAmount);
    }

    function transferHighestBidToSSPM(uint256 lotId) external override nonReentrant {
        LotItem storage lotItem = lots[lotId];
        uint256 ethAmount = lotItem.highestBidAmount;

        if (block.number <= lotItem.endBlock) revert AuctionNotEnded();
        if (ethAmount == 0) revert NoBidPlaced();
        if (lotItem.ethExtracted) revert AlreadyClaimed();

        lotItem.ethExtracted = true;
        IStaderStakePoolManager(staderConfig.getStakePoolManager()).receiveEthFromAuction{value: ethAmount}();
        emit ETHClaimed(lotId, staderConfig.getStakePoolManager(), ethAmount);
    }

    function extractNonBidSD(uint256 lotId) external override {
        LotItem storage lotItem = lots[lotId];
        if (block.number <= lotItem.endBlock) revert AuctionNotEnded();
        if (lotItem.highestBidAmount > 0) revert LotWasAuctioned();
        if (lotItem.sdAmount == 0) revert AlreadyClaimed();

        uint256 _sdAmount = lotItem.sdAmount;
        lotItem.sdAmount = 0;
        if (!IERC20(staderConfig.getStaderToken()).transfer(staderConfig.getStaderTreasury(), _sdAmount)) {
            revert SDTransferFailed();
        }
        emit UnsuccessfulSDAuctionExtracted(lotId, _sdAmount, staderConfig.getStaderTreasury());
    }

    function withdrawUnselectedBid(uint256 lotId) external override nonReentrant {
        LotItem storage lotItem = lots[lotId];
        if (block.number <= lotItem.endBlock) revert AuctionNotEnded();
        if (msg.sender == lotItem.highestBidder) revert BidWasSuccessful();

        uint256 withdrawalAmount = lotItem.bids[msg.sender];
        if (withdrawalAmount == 0) revert InSufficientETH();

        lotItem.bids[msg.sender] -= withdrawalAmount;

        // send the funds
        (bool success, ) = payable(msg.sender).call{value: withdrawalAmount}('');
        if (!success) revert ETHWithdrawFailed();

        emit BidWithdrawn(lotId, msg.sender, withdrawalAmount);
    }

    // SETTERS
    function updateStaderConfig(address _staderConfig) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        UtilLib.checkNonZeroAddress(_staderConfig);
        staderConfig = IStaderConfig(_staderConfig);
        emit UpdatedStaderConfig(_staderConfig);
    }

    function updateDuration(uint256 _duration) external override {
        UtilLib.onlyManagerRole(msg.sender, staderConfig);
        if (_duration < MIN_AUCTION_DURATION) revert ShortDuration();
        duration = _duration;
        emit AuctionDurationUpdated(duration);
    }

    function updateBidIncrement(uint256 _bidIncrement) external override {
        UtilLib.onlyManagerRole(msg.sender, staderConfig);
        bidIncrement = _bidIncrement;
        emit BidIncrementUpdated(_bidIncrement);
    }
}