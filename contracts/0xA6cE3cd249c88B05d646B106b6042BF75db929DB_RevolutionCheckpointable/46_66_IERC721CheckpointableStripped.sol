// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface IERC721CheckpointableStripped {
    /// @notice The current number of votes for an account
    /// @param account The account address
    function getCurrentVotes(address account) external view returns (uint96);

    /// @notice The number of votes for an account at a past timestamp
    /// @param account The account address
    /// @param blockNumber The past block number
    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint96);
}