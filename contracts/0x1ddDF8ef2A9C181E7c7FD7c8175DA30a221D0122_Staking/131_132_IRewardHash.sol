// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

/**
 *  @title Tracks the IPFS hashes that are generated for rewards
 */
interface IRewardHash {
    struct CycleHashTuple {
        string latestClaimable; // hash of last claimable cycle before/including this cycle
        string cycle; // cycleHash of this cycle
    }

    event CycleHashAdded(uint256 cycleIndex, string latestClaimableHash, string cycleHash);

    /// @notice Sets a new (claimable, cycle) hash tuple for the specified cycle
    /// @param index Cycle index to set. If index >= LatestCycleIndex, CycleHashAdded is emitted
    /// @param latestClaimableIpfsHash IPFS hash of last claimable cycle before/including this cycle
    /// @param cycleIpfsHash IPFS hash of this cycle
    function setCycleHashes(
        uint256 index,
        string calldata latestClaimableIpfsHash,
        string calldata cycleIpfsHash
    ) external;

    ///@notice Gets hashes for the specified cycle
    ///@return latestClaimable lastest claimable hash for specified cycle, cycle latest hash (possibly non-claimable) for specified cycle
    function cycleHashes(uint256 index)
        external
        view
        returns (string memory latestClaimable, string memory cycle);
}