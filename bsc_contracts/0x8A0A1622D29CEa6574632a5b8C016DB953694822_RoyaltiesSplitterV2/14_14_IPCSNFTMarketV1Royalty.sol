// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPCSNFTMarketV1Royalty {
    
    function pendingRevenue(
        address creator
    ) external view returns (uint256);

    function claimPendingRevenue() external;
}