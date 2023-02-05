// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../libraries/BatchAuctionQ.sol";

interface IBatchAuction {
    struct Collateral {
        //ERC20 token for the required collateral
        address addr;
        // The amount of tokens required for the collateral
        uint80 amount;
    }

    struct Auction {
        // Seller wallet address
        address seller;
        // ERC1155 address
        address optionTokenAddr;
        // ERC1155 Id of auctioned token
        uint256[] optionTokens;
        // ERC20 Token to bid for optionToken
        address biddingToken;
        // List of collateral requirements for each ERC20 token
        Collateral[] collaterals;
        // Price per optionToken denominated in biddingToken
        int256 minPrice;
        // Minimum optionToken amount acceptable for a single bid
        uint256 minBidSize;
        // Total available optionToken amount
        uint256 totalSize;
        // Remaining available optionToken amount
        // This figure is updated only after settlement
        uint256 availableSize;
        // Auction end time
        uint256 endTime;
        // clearing price
        int256 clearingPrice;
        // has the auction been settled
        bool settled;
        // whitelist address
        address whitelist;
    }

    function createAuction(
        address optionTokenAddr,
        uint256[] calldata optionTokens,
        address biddingToken,
        Collateral[] calldata collaterals,
        int256 minPrice,
        uint256 minBidSize,
        uint256 totalSize,
        uint256 endTime,
        address whitelist
    ) external returns (uint256 auctionId);

    function placeBid(uint256 auctionId, uint256 quantity, int256 price) external;

    function cancelBid(uint256 auctionId, uint256 bidId) external;

    function auctions(uint256) external view returns (IBatchAuction.Auction memory auction);

    function settleAuction(uint256 auctionId) external returns (int256 clearingPrice, uint256 totalSold);

    function claim(uint256 auctionId) external;

    function getBids(uint256 auctionId) external view returns (uint256[] memory);
}