// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import { INounsSeeder } from "contracts/interfaces/INounsSeeder.sol";

interface IRoboNounsVRGDA {
    event AuctionSettled(uint256 indexed nounId, address winner, uint256 amount);
    event AuctionReservePriceUpdated(uint256 reservePrice);
    event AuctionPriceDecayIntervalUpdated(uint256 priceDecayInterval);
    event AuctionTargetPriceUpdated(int256 targetPrice);
    event AuctionPriceDecayPercentUpdated(int256 priceDecayPercent);
    event AuctionPerTimeUnitUpdated(uint256 perTimeUnit);

    function buyNow(uint256 expectedBlockNumber) external payable;

    function fetchNextNoun()
        external
        view
        returns (uint256 nounId, INounsSeeder.Seed memory seed, string memory svg, uint256 price, uint256 blockNumber);

    function setReservePrice(uint256 reservePrice) external;
}