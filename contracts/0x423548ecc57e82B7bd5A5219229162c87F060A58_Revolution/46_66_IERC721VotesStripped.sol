// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface IERC721VotesStripped {
    /// @notice The current number of votes for an account
    /// @param account The account address
    function getVotes(address account) external view returns (uint256);

    /// @notice The number of votes for an account at a past timestamp
    /// @param account The account address
    /// @param timestamp The past timestamp
    function getPastVotes(address account, uint256 timestamp) external view returns (uint256);
}