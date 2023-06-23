// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IAuctionInfo.sol";

interface IEthAuction is IAuctionInfo {
    /**
     * @dev Create a `msg.value` bid for a NFT.
     */
    function createBid(uint24 nftId) external payable;
}