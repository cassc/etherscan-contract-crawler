// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title The interface to access the OG stats contract
 * @author nfttank.eth
 */
interface OGStatsInterface {

    /**
    * @notice Gets the OG stats for a given address
    * @param addressToScan The address to scan
    * @param checkUpToBalance The maxium balance to check for the tiers and enumerate tokens. Means: Whale if more than this quantity.
    */
    function scan(address addressToScan, uint16 checkUpToBalance) external view returns (Stats memory);
}

struct Stats {
    uint256 balance;
    bool ogDozen;
    bool meme;
    bool honorary;
    bool maxedOut;
    uint256[] tokenIds;
}