// SPDX-License-Identifier: GPL-3.0

/// @title Interface for Wizard Auction Houses

pragma solidity ^0.8.6;

// RH:
interface IAuctionHouse {
    struct Auction {
        // ID for the Wizard (ERC721 token ID)
        uint256 wizardId;
        // The current highest bid amount
        uint256 amount;
        // The time that the auction started
        uint256 startTime;
        // The time that the auction is scheduled to end
        uint256 endTime;
        // The address of the current highest bid
        address payable bidder;
        // Whether or not the auction has been settled
        bool settled;
        // Whether or not it's a whitelist day
        bool isWhitelistDay;
    }

    // RH: updated event
    event AuctionCreated(
        uint256 indexed wizardId,
        uint256 indexed aId,
        uint256 startTime,
        uint256 endTime,
        bool oneOfOne,
        bool isWhitelistDay
    );

    event AuctionCapUpdated(uint256 indexed cap);

    event AuctionCapReached(uint256 indexed cap);

    event AuctionBid(
        uint256 indexed wizardId,
        uint256 indexed aId,
        address sender,
        uint256 value,
        bool extended
    );

    event AuctionExtended(
        uint256 indexed wizardId,
        uint256 indexed aId,
        uint256 endTime
    );

    event AuctionSettled(
        uint256 indexed wizardId,
        uint256 indexed aId,
        address winner,
        uint256 amount
    );

    event AuctionTimeBufferUpdated(uint256 timeBuffer);

    event AuctionOneOfOne(bool auctionOneOfOne);

    event AuctionReservePriceUpdated(uint256 reservePrice);

    event AuctionMinBidIncrementPercentageUpdated(
        uint256 minBidIncrementPercentage
    );

    event CreatorsDAOUpdated(address creatorsDAO);

    event DAOWalletUpdated(address daoWallet);

    function settleAuction(uint256 aId) external;

    function settleCurrentAndCreateNewAuction() external;

    function createBid(uint256 wizardId, uint256 aid) external payable;

    function pause() external;

    function unpause() external;

    function setAuctionOneOfOne(bool auctionOneOfOne) external;

    function setCreatorsDAO(address creatorsDAO) external;

    function setDAOWallet(address daoWallet) external;

    function setWizardCap(uint256 _cap) external;

    function setTimeBuffer(uint256 timeBuffer) external;

    function setOneOfOneId(uint48 _oneOfOneId) external;

    function setReservePrice(uint256 reservePrice) external;

    // RH:
    function setWhitelistAddresses(address[] calldata _whitelistAddrs) external;

    function stopWhitelistDay() external;

    function setMinBidIncrementPercentage(uint8 minBidIncrementPercentage)
        external;
}