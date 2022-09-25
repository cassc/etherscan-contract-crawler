// SPDX-License-Identifier: GPL-3.0

//     `..        `.  `... `......`.. ..
//  `..   `..    `. ..     `..  `..    `..
// `..          `.  `..    `..   `..
// `..         `..   `..   `..     `..
// `..        `...... `..  `..        `..
//  `..   `..`..       `.. `..  `..    `..
//    `.... `..         `..`..    `.. ..
pragma solidity 0.8.16;

import { ICatsAuctionHouse } from "./ICatsAuctionHouse.sol";
import { IAuctionable } from "../cats/IAuctionable.sol";
import { ICatcoin } from "../catcoin/ICatcoin.sol";

library CatsAuctionHouseStorage {
    struct Layout {
        // Address of the treasury
        address treasury;
        // Address of the developes
        address devs;
        // The Cats ERC721 token contract
        IAuctionable cats;
        // The address of the WETH contract
        address weth;
        // The minimum amount of time left in an auction after a new bid is created
        uint256 timeBuffer;
        // The minimum price accepted in an auction
        uint256 reservePriceInETH;
        // The minimum price accepted in an auction
        uint256 reservePriceInCatcoins;
        // The minimum percentage difference between the last bid amount and the current bid
        uint8 minBidIncrementPercentage;
        // The minimum unitary difference between the last bid amount and the current bid
        uint8 minBidIncrementUnit;
        // The duration of a single auction
        uint256 duration;
        // The active auction
        ICatsAuctionHouse.Auction auction;
        // True if the Auction House is paused
        bool paused;
        // True if next auction will settle in ETH
        bool ethAuctions;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("cats.contracts.storage.auction.house");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}