// SPDX-License-Identifier: UNLICENSED
// © Copyright 2021. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity 0.8.5; 

/// @title IGBM GBM auction interface
/// @dev See GBM.auction on how to use this contract
/// @author Guillaume Gonnaud and Javier Fraile
interface IGBM {
    
    //Event emitted when an auction is being setup
    event Auction_Initialized(uint256 indexed _auctionID, uint256 indexed _tokenID, address indexed _contractAddress, bytes4 _tokenKind);

    //Event emitted when the start time of an auction changes (due to admin interaction )
    event Auction_StartTimeUpdated(uint256 indexed _auctionID, uint256 _startTime);

    //Event emitted when the end time of an auction changes (be it due to admin interaction or bid at the end)
    event Auction_EndTimeUpdated(uint256 indexed _auctionID, uint256 _endTime);
    
    //Event emitted when a Bid is placed
    event Auction_BidPlaced(uint256 indexed _auctionID, address indexed _bidder, uint256 _bidAmount);

    //Event emitted when a bid is removed (due to a new bid displacing it)
    event Auction_BidRemoved(uint256 indexed _auctionID,  address indexed _bidder, uint256 _bidAmount);

    //Event emitted when incentives are paid (due to a new bid rewarding the _earner bid)
    event Auction_IncentivePaid(uint256 indexed _auctionID,  address indexed _earner, uint256 _incentiveAmount);

    //Event emitted when a token is claimed
    event Auction_Claimed(uint256 indexed _auctionID);


    function bid(uint256 _auctionID, uint256 _bidAmount, uint256 _highestBid) external payable;
    function claim(uint256 _auctionID) external;
    function registerAnAuctionContract(address _contract, address _initiator) external;
    function setBiddingAllowed(address _contract, bool _value) external;
    function registerAnAuctionToken(address _contract, uint256 _tokenId, bytes4 _tokenKind, uint256 _tokenAmount, address _initiator) external;
    function modifyAnAuctionToken(uint256 _auctionID, address _initiator) external;
    function modifyAnAuctionToken(uint256 _auctionID, uint256 _tokenAmount, address _initiator) external;
    function massRegistrerERC721Each(address _initiator, address _ERC721Contract, uint256 _tokenIDStart, uint256 _tokenIDEnd) external;
    function massRegistrerERC1155Each(address _initiator, address _ERC1155Contract, uint256 _tokenID, uint256 _indexStart, uint256 _indexEnd) external;

    function owner() external returns(address);
    
    function getAuctionID(address _contract, bytes4 _tokenKind, uint256 _tokenID, uint256 _tokenIndex) external view returns(uint256);
    function getTokenId(uint256 _auctionID) external view returns(uint256);
    function getContractAddress(uint256 _auctionID) external view returns(address);
    function getTokenKind(uint256 _auctionID) external view returns(bytes4);
    function getTokenAmount(uint256 _auctionID) external view returns(uint256);

    function getAuctionHighestBidder(uint256 _auctionID) external view returns(address);
    function getAuctionHighestBid(uint256 _auctionID) external view returns(uint256);
    function getAuctionDebt(uint256 _auctionID) external view returns(uint256);
    function getAuctionDueIncentives(uint256 _auctionID) external view returns(uint256);

    function getAuctionStartTime(uint256 _auctionID) external view returns(uint256);
    function getAuctionEndTime(uint256 _auctionID) external view returns(uint256);
    function getHammerTimeDuration(uint256 _auctionID) external view returns(uint256);
    function getAuctionBidDecimals(uint256 _auctionID) external view returns(uint256);
    function getAuctionStepMin(uint256 _auctionID) external view returns(uint256);
    function getAuctionIncMin(uint256 _auctionID) external view returns(uint256);
    function getAuctionIncMax(uint256 _auctionID) external view returns(uint256);
    function getAuctionBidMultiplier(uint256 _auctionID) external view returns(uint256);

}