// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IAuctionInfo {
    /**
     * @return The auctioned NFT (or maybe any other type of token).
     */
    function getAuctionedToken() external view returns (address);

    /**
     * @return An array with all the token ids that 
     * can currently get auctioned.
     */
    function getIdsToAuction() external view returns (uint24[] memory);

    /**
     * @return The current minimum bid price for an auctionable `tokenId`.
     * If `tokenId` not in `this.getIdsToAuction()`, it should revert.
     */
    function getMinPriceFor(uint24 tokenId) external view returns (uint96);
}