// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISnapshotFeature {

    /**
     * @dev Returns the current snapshot Id.
     */
    function getCurrentSnapshotId() external view returns (uint256);

    /**
     * @dev Take a snapshot.
     */
    function snapshot() external;

}