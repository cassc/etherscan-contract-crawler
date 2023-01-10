// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IPioneerNFT{

    /**
     * @dev Sale will call to mint to buyer`.
     */
    function saleMint(address buyer , uint256 amount) external;

     /**
     * @dev To Check Whether Auction Ended or not`.
     */
    function hasAuctionStarted() external view returns (bool);
}