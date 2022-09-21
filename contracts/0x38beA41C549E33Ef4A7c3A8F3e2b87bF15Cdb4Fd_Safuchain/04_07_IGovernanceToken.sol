// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/**
 * @title Governance token interface.
 */
interface IGovernanceToken {
    /// @notice A checkpoint for marking number of votes as of a given block.
    struct Checkpoint {
        // The 32-bit unsigned integer is valid until these estimated dates for these given chains:
        //  - BSC: Sat Dec 23 2428 18:23:11 UTC
        //  - ETH: Tue Apr 18 3826 09:27:12 UTC
        // This assumes that block mining rates don't speed up.
        uint32 blockNumber;
        // This type is set to `uint224` for optimizations purposes (i.e., specifically to fit in a 32-byte block). It
        // assumes that the number of votes for the implementing governance token never exceeds the maximum value for a
        // 224-bit number.
        uint224 votes;
    }

    /**
     * @notice Determine the number of votes for an account as of a block number.
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check.
     * @param blockNumber The block number to get the vote balance at.
     * @return The number of votes the account had as of the given block.
     */
    function getVotesAtBlock(address account, uint32 blockNumber) external view returns (uint224);

    /// @notice Emitted whenever a new delegate is set for an account.
    event DelegateChanged(address delegator, address currentDelegate, address newDelegate);

    /// @notice Emitted when a delegate's vote count changes.
    event DelegateVotesChanged(address delegatee, uint224 oldVotes, uint224 newVotes);
}