// SPDX-License-Identifier: GPL-3.0

//     `..        `.  `... `......`.. ..
//  `..   `..    `. ..     `..  `..    `..
// `..          `.  `..    `..   `..
// `..         `..   `..   `..     `..
// `..        `...... `..  `..        `..
//  `..   `..`..       `.. `..  `..    `..
//    `.... `..         `..`..    `.. ..

pragma solidity 0.8.16;
import { IAuctionable } from "../cats/IAuctionable.sol";

interface ICatsAuctionHouse {
    struct Auction {
        // ID for the Cats (ERC721 token ID)
        uint256 catId;
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
        // Which type of currency is used to settle the auction
        bool isETH;
    }

    event AuctionCreated(uint256 indexed catId, uint256 startTime, uint256 endTime);

    event AuctionBid(uint256 indexed catId, address sender, uint256 value, bool extended);

    event AuctionExtended(uint256 indexed catId, uint256 endTime);

    event AuctionSettled(uint256 indexed catId, address winner, uint256 amount);

    event AuctionTimeBufferUpdated(uint256 timeBuffer);

    event AuctionDurationUpdated(uint256 AuctionDurationUpdated);

    event AuctionReservePriceInETHUpdated(uint256 reservePriceInETH);

    event AuctionReservePriceInCatcoinsUpdated(uint256 reservePriceInCatcoins);

    event AuctionMinBidIncrementPercentageUpdated(uint256 minBidIncrementPercentage);

    event AuctionMinBidIncrementUnitUpdated(uint256 minBidIncrementUnit);

    event ETHAuctionsUpdated(bool ethAuctions);

    function settleAuction(uint256[] calldata tokenIds) external;

    function settleCurrentAndCreateNewAuction(uint256[] calldata tokenIds) external;

    function createBid(uint256 catId, uint256 amount) external payable;

    function pause() external;

    function unpause() external;

    function setConfig(
        address treasury,
        address devs,
        IAuctionable cats,
        address weth,
        uint256 timeBuffer,
        uint256 reservePriceInETH,
        uint256 reservePriceInCatcoins,
        uint8 minBidIncrementPercentage,
        uint8 minBidIncrementUnit,
        uint256 duration
    ) external;

    function setTimeBuffer(uint256 timeBuffer) external;

    function setReservePriceInETH(uint256 reservePriceInETH) external;

    function setReservePriceInCatcoins(uint256 reservePriceInCatcoins) external;

    function setMinBidIncrementPercentage(uint8 minBidIncrementPercentage) external;

    function setMinBidIncrementUnit(uint8 minBidIncrementUnit) external;

    function setETHAuctions(bool ethAuctions) external;

    function setDevs(address devs_) external;

    function setTreasury(address treasury) external;

    function treasury() external view returns (address);

    function devs() external view returns (address);

    function cats() external view returns (IAuctionable);

    function weth() external view returns (address);

    function timeBuffer() external view returns (uint256);

    function setDuration(uint256 duration) external;

    function reservePriceInETH() external view returns (uint256);

    function reservePriceInCatcoins() external view returns (uint256);

    function minBidIncrementPercentage() external view returns (uint8);

    function minBidIncrementUnit() external view returns (uint8);

    function duration() external view returns (uint256);

    function auction() external view returns (Auction memory);

    function paused() external view returns (bool);

    function ethAuctions() external view returns (bool);
}