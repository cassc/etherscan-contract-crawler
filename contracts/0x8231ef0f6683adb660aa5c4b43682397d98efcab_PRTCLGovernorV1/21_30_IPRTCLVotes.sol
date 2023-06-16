// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Interface for using {PRTCLCollections721V1} as voting tokens per collection.
/// @author Particle Collection - valdi.eth
/// @notice Manages base voting data
/// @dev Modified version of OpenZeppelin's {IVotes} to accommodate multiple collections.
interface IPRTCLVotes {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate, uint256 collectionId);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance, uint256 collectionId);

    /**
     * @dev Returns the current amount of votes that `account` has for collection `collectionId`.
     */
    function getVotes(address account, uint256 collectionId) external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`)
     * for collection `collectionId`.
     */
    function getPastVotes(address account, uint256 blockNumber, uint256 collectionId) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`),
     * for collection `collectionId`.
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 blockNumber, uint256 collectionId) external view returns (uint256);

    /**
     * @dev Returns the current total supply of votes for a given collection.
     */
    function getTotalSupply(uint256 collectionId) external view returns (uint256);

    /**
     * @dev Delegates `collectionId` collection votes from the sender to `delegatee`.
     */
    function delegate(address delegatee, uint256 collectionId) external;

    /**
     * @dev Returns the delegate that `account` has chosen for `collectionId` collection.
     */
    function delegates(address account, uint256 collectionId) external view returns (address);
}