// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/interfaces/IValidatorPool.sol";
import "contracts/interfaces/IETHDKG.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutableETHDKG.sol";
import "contracts/utils/auth/ImmutableValidatorPool.sol";
import "contracts/utils/auth/ImmutableDynamics.sol";
import "contracts/libraries/snapshots/SnapshotRingBuffer.sol";

abstract contract SnapshotsStorage is
    ImmutableETHDKG,
    ImmutableValidatorPool,
    SnapshotRingBuffer,
    ImmutableDynamics
{
    uint256 internal immutable _epochLength;

    uint256 internal immutable _chainId;

    // Number of ethereum blocks that we should wait between snapshots. Mainly used to prevent the
    // submission of snapshots in short amount of time by validators that could be potentially being
    // malicious
    uint32 internal _minimumIntervalBetweenSnapshots;

    // after how many eth blocks of not having a snapshot will we start allowing more validators to
    // make it
    uint32 internal _snapshotDesperationDelay;

    // how quickly more validators will be allowed to make a snapshot, once
    // _snapshotDesperationDelay has passed
    uint32 internal _snapshotDesperationFactor;

    //epoch counter wrapped in a struct
    Epoch internal _epoch;
    //new snapshot ring buffer
    SnapshotBuffer internal _snapshots;

    constructor(
        uint256 chainId_,
        uint256 epochLength_
    ) ImmutableFactory(msg.sender) ImmutableETHDKG() ImmutableValidatorPool() ImmutableDynamics() {
        _chainId = chainId_;
        _epochLength = epochLength_;
    }

    function _getEpochFromHeight(uint32 height_) internal view override returns (uint32) {
        if (height_ <= _epochLength) {
            return 1;
        }
        if (height_ % _epochLength == 0) {
            return uint32(height_ / _epochLength);
        }
        return uint32((height_ / _epochLength) + 1);
    }

    function _getSnapshots() internal view override returns (SnapshotBuffer storage) {
        return _snapshots;
    }

    function _epochRegister() internal view override returns (Epoch storage) {
        return _epoch;
    }
}