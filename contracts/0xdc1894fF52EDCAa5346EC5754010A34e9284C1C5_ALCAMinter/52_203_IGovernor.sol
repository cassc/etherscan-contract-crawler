// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface IGovernor {
    event ValueUpdated(
        uint256 indexed epoch,
        uint256 indexed key,
        bytes32 indexed value,
        address who
    );

    event SnapshotTaken(
        uint256 chainId,
        uint256 indexed epoch,
        uint256 height,
        address indexed validator,
        bool isSafeToProceedConsensus,
        bytes signatureRaw
    );

    function updateValue(uint256 epoch, uint256 key, bytes32 value) external;
}