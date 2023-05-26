// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IStaking
interface IVotingPower {
    struct Snapshot {
        uint32 beforeBlock;
        uint96 ownPower;
        uint96 delegatedPower;
    }

    /// @dev Voting power integrants
    struct Power {
        uint96 own; // voting power that remains after delegating to others
        uint96 delegated; // voting power delegated by others
    }

    /// @notice Returns total voting power staked
    /// @dev "own" and "delegated" voting power summed up
    function totalVotingPower() external view returns (uint256);

    /// @notice Returns total "own" and total "delegated" voting power separately
    /// @dev Useful, if "own" and "delegated" voting power treated differently
    function totalPower() external view returns (Power memory);

    /// @notice Returns global snapshot for given block
    /// @param blockNum - block number to get state at
    /// @param hint - off-chain computed index of the required snapshot
    function globalSnapshotAt(uint256 blockNum, uint256 hint)
        external
        view
        returns (Snapshot memory);

    /// @notice Returns snapshot on given block for given account
    /// @param _account - account to get snapshot for
    /// @param blockNum - block number to get state at
    /// @param hint - off-chain computed index of the required snapshot
    function snapshotAt(
        address _account,
        uint256 blockNum,
        uint256 hint
    ) external view returns (Snapshot memory);

    /// @dev Returns block number of the latest global snapshot
    function latestGlobalsSnapshotBlock() external view returns (uint256);

    /// @dev Returns block number of the given account latest snapshot
    function latestSnapshotBlock(address _account)
        external
        view
        returns (uint256);

    /// @dev Returns number of global snapshots
    function globalsSnapshotLength() external view returns (uint256);

    /// @dev Returns number of snapshots for given account
    function snapshotLength(address _account) external view returns (uint256);

    /// @dev Returns global snapshot at given index
    function globalsSnapshot(uint256 _index)
        external
        view
        returns (Snapshot memory);

    /// @dev Returns snapshot at given index for given account
    function snapshot(address _account, uint256 _index)
        external
        view
        returns (Snapshot memory);
}