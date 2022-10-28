// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

// Interface for NichoNFTAuction
interface INichoNFTAuction {
    function cancelAuctionFromFixedSaleCreation(
        address tokenAddress, 
        uint tokenId
    ) external;

    function getAuctionStatus(address tokenAddress, uint tokenId)
        external
        view
        returns (bool);
}