// SPDX-License-Identifier: GPL-3.0

/// @title Interface for Auction Houses

pragma solidity ^0.8.6;

interface IAuctionHouse {
    /// @notice MintType enum used to distinguish nft mint types
    enum MintType {
        Promo,
        Allowlist,
        Auction,
        Raffle,
        PublicSale,
        CreditCard,
        WildPass
    }

    /** @notice Emitted when a new token is minted
        @dev Generalized mint event, uses the MintType parameter to distinguish mint types
        @param to - address of the token owner
        @param tokenIds - token ID array
        @param mintType - MintType enum
        @param amountPaid - amount paid for the mint
        @param isDelegated - whether or not the mint was delegated
        @param delegatedVault - address of the delegated vault
        @param oasisUsed - whether or not an Oasis pass was used. Can be true even if oasisIds is empty (ex. oasis price in public sale).
        @param oasisIds - Oasis pass ID array (same index/length as tokenId). Empty if ids not specified.
    */
    event TokenMint(address indexed to, uint256[] tokenIds, MintType indexed mintType, uint256 amountPaid, bool isDelegated, address delegatedVault, bool oasisUsed, uint256[] oasisIds);

    /** @notice Emitted when AuctionHouse.revealMetadata(_newBaseURI) is called
        @dev Used to trigger webhook listeners
     */
    event MetadataRevealed();

    event AddedToAllowList(address indexed addedAddress, uint8 indexed state);
    event RemovedFromAllowList(address indexed removedAddress);

    event AuctionBid(address sender, uint256 value, bool extended);

    event AuctionSettled();

    event AuctionTimeBufferUpdated(uint256 timeBuffer);

    event AuctionMinimumBidUpdated(uint256 minimumBid);

    event AuctionMinBidIncrementUpdated(uint256 minBidIncrementPercentage);

    event AuctionDurationUpdated(uint256 duration);

    function setAuctionWinners(address[] memory _auctionWinners, uint256[] memory _price) external;

    function setTimes(uint256 _startTime, uint256 _duration) external;

    function createBid() external payable;

    function pause() external;

    function unpause() external;

    function setTimeBuffer(uint256 timeBuffer) external;

    function setDuration(uint256 _duration) external;
}