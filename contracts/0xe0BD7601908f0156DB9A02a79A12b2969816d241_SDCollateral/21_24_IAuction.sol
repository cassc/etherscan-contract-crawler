// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import '../IStaderConfig.sol';

interface IAuction {
    // errors
    error InSufficientETH();
    error ETHWithdrawFailed();
    error AuctionEnded();
    error AuctionNotEnded();
    error ShortDuration();
    error notQualified();
    error AlreadyClaimed();
    error NoBidPlaced();
    error BidWasSuccessful();
    error InSufficientBid();
    error LotWasAuctioned();
    error SDTransferFailed();

    // events
    event UpdatedStaderConfig(address indexed _staderConfig);
    event LotCreated(uint256 lotId, uint256 sdAmount, uint256 startBlock, uint256 endBlock, uint256 bidIncrement);
    event BidPlaced(uint256 lotId, address indexed bidder, uint256 bid);
    event BidWithdrawn(uint256 lotId, address indexed withdrawalAccount, uint256 amount);
    event BidCancelled(uint256 lotId);
    event SDClaimed(uint256 lotId, address indexed highestBidder, uint256 sdAmount);
    event ETHClaimed(uint256 lotId, address indexed sspm, uint256 ethAmount);
    event AuctionDurationUpdated(uint256 duration);
    event BidIncrementUpdated(uint256 _bidIncrement);
    event UnsuccessfulSDAuctionExtracted(uint256 lotId, uint256 sdAmount, address indexed recipient);

    // struct
    struct LotItem {
        uint256 startBlock;
        uint256 endBlock;
        uint256 sdAmount;
        mapping(address => uint256) bids;
        address highestBidder;
        uint256 highestBidAmount;
        bool sdClaimed;
        bool ethExtracted;
    }

    // methods
    function createLot(uint256 _sdAmount) external;

    function addBid(uint256 lotId) external payable;

    function claimSD(uint256 lotId) external;

    function transferHighestBidToSSPM(uint256 lotId) external;

    function extractNonBidSD(uint256 lotId) external;

    function withdrawUnselectedBid(uint256 lotId) external;

    // setters
    function updateStaderConfig(address _staderConfig) external;

    function updateDuration(uint256 _duration) external;

    function updateBidIncrement(uint256 _bidIncrement) external;

    //getters
    function staderConfig() external view returns (IStaderConfig);

    function nextLot() external view returns (uint256);

    function bidIncrement() external view returns (uint256);

    function duration() external view returns (uint256);
}