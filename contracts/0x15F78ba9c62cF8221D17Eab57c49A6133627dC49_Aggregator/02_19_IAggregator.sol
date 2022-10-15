// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

/** 
 * @title Staking Aggregator Interface for Ethereum Network
 * @notice Executes different functions for the user accordingly
 */
interface IAggregator {
    /**
     * @notice Routes user's investment into different protocols
     * @param data - byte array which has unique prefix for different strategy 
     * @return true if operation succeeded
     */
    function stake(bytes[] calldata data) payable external returns (bool);

    /**
     * @notice Returns user's investment from different protocols
     * @param data - byte array which has unique prefix for different strategy 
     * @return true if operation succeeded
     */
    function unstake(bytes[] calldata data) payable external returns (bool);

    /**
     * @notice Transfers earned rewards to nft owner
     * @dev Calls `publicSettle()` internally to ensure all rewards are claimed
     * @param tokenId - representation of user's nft
     */
    function disperseRewards(uint256 tokenId) external;

    /**
     * @notice Transfers earned rewards to nft owner
     * @param tokenId - representation of user's nft
     */
    function claimRewards(uint256 tokenId) external;

    /**
     * @notice Transfers all earned rewards to nft owner
     * @param tokenIds - An array containing the representation of user's nft
     */
    function batchClaimRewards(uint256[] calldata tokenIds) external;
}