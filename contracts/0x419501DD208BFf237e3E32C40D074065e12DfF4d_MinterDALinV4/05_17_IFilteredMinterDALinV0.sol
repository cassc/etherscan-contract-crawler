// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

import "./IFilteredMinterV0.sol";

pragma solidity ^0.8.0;

/**
 * @title This interface extends the IFilteredMinterV0 interface in order to
 * add support for linear descending auctions.
 * @author Art Blocks Inc.
 */
interface IFilteredMinterDALinV0 is IFilteredMinterV0 {
    /// Auction details updated for project `projectId`.
    event SetAuctionDetails(
        uint256 indexed projectId,
        uint256 _auctionTimestampStart,
        uint256 _auctionTimestampEnd,
        uint256 _startPrice,
        uint256 _basePrice
    );

    /// Auction details cleared for project `projectId`.
    event ResetAuctionDetails(uint256 indexed projectId);

    /// Minimum allowed auction length updated
    event MinimumAuctionLengthSecondsUpdated(
        uint256 _minimumAuctionLengthSeconds
    );

    function minimumAuctionLengthSeconds() external view returns (uint256);
}