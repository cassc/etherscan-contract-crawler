// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import {IDualAuction} from "./IDualAuction.sol";

/**
 * @notice Interface for Auction factory contracts
 */
interface IAuctionFactory {
    event AuctionCreated(
        address indexed bidAsset,
        address indexed askAsset,
        uint256 endDate,
        address indexed creator,
        address newAuctionAddress
    );

    /// @notice Some parameters are invalid
    error InvalidParams();

    /**
     * @notice Creates a new auction
     * @param bidAsset The asset that bids are made with
     * @param askAsset The asset that asks are made with
     * @param minPrice The minimum allowed price in terms of bidAsset
     * @param maxPrice The maximum allowed price in terms of bidAsset
     * @param tickWidth The spacing between valid prices
     * @param endDate The timestamp at which the auction will end
     */
    function createAuction(
        address bidAsset,
        address askAsset,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 tickWidth,
        uint256 priceDenominator,
        uint256 endDate
    ) external returns (IDualAuction);
}