// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

import "./IFilteredMinterV0.sol";

pragma solidity ^0.8.0;

/**
 * @title This interface extends the IFilteredMinterV0 interface in order to
 * add support for exponential descending auctions.
 * @author Art Blocks Inc.
 */
interface IFilteredMinterDAExpV0 is IFilteredMinterV0 {
    /// Auction details updated for project `projectId`.
    event SetAuctionDetails(
        uint256 indexed projectId,
        uint256 _auctionTimestampStart,
        uint256 _priceDecayHalfLifeSeconds,
        uint256 _startPrice,
        uint256 _basePrice
    );

    /// Auction details cleared for project `projectId`.
    event ResetAuctionDetails(uint256 indexed projectId);

    /// Maximum and minimum allowed price decay half lifes updated.
    event AuctionHalfLifeRangeSecondsUpdated(
        uint256 _minimumPriceDecayHalfLifeSeconds,
        uint256 _maximumPriceDecayHalfLifeSeconds
    );

    function minimumPriceDecayHalfLifeSeconds() external view returns (uint256);

    function maximumPriceDecayHalfLifeSeconds() external view returns (uint256);
}