// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IBatchAuctionSeller {
    function settledAuction(uint256 auctionId, uint256 totalSold, int256 clearingPrice) external;

    function novate(address recipient, uint256 amount, uint256[] calldata options, uint256[] calldata counterparty) external;
}