// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/parsers/BClaimsParserLibrary.sol";
import "contracts/interfaces/ISnapshots.sol";
import "contracts/libraries/errors/SnapshotsErrors.sol";

struct Epoch {
    uint32 _value;
}

struct SnapshotBuffer {
    Snapshot[6] _array;
}

library RingBuffer {
    /***
     * @dev: Sets a new snapshot safely inside the ring buffer.
     * @param epochFor_: anonymous function to convert a height in an _epoch value.
     * @param new_: the new snapshot.
     * @return the the epoch number where the snapshot was stored.
     */
    function set(
        SnapshotBuffer storage self_,
        function(uint32) returns (uint32) epochFor_,
        Snapshot memory new_
    ) internal returns (uint32) {
        //get the epoch corresponding to the blocknumber
        uint32 epoch = epochFor_(new_.blockClaims.height);
        //gets the snapshot that was at that location of the buffer
        Snapshot storage old = self_._array[indexFor(self_, epoch)];
        //checks if the new snapshot height is greater than the previous
        if (new_.blockClaims.height <= old.blockClaims.height) {
            revert SnapshotsErrors.InvalidRingBufferBlockHeight(
                new_.blockClaims.height,
                old.blockClaims.height
            );
        }
        unsafeSet(self_, new_, epoch);
        return epoch;
    }

    /***
     * @dev: Sets a new snapshot inside the ring buffer in a specific index.
     * Don't call this function directly, use set() instead.
     * @param new_: the new snapshot.
     * @param epoch_: the index (epoch) where the new snapshot will be stored.
     */
    function unsafeSet(SnapshotBuffer storage self_, Snapshot memory new_, uint32 epoch_) internal {
        self_._array[indexFor(self_, epoch_)] = new_;
    }

    /**
     * @dev gets the snapshot value at an specific index (epoch).
     * @param epoch_: the index to retrieve a snapshot.
     * @return the snapshot stored at the epoch_ location.
     */
    function get(
        SnapshotBuffer storage self_,
        uint32 epoch_
    ) internal view returns (Snapshot storage) {
        return self_._array[indexFor(self_, epoch_)];
    }

    /**
     * @dev calculates the congruent value for current epoch in respect to the array length
     * for index to be replaced with most recent epoch.
     * @param epoch_ epoch_ number associated with the snapshot.
     * @return the index corresponding to the epoch number.
     */
    function indexFor(SnapshotBuffer storage self_, uint32 epoch_) internal view returns (uint256) {
        if (epoch_ == 0) {
            revert SnapshotsErrors.EpochMustBeNonZero();
        }
        return epoch_ % self_._array.length;
    }
}

library EpochLib {
    /***
     * @dev sets an epoch value in Epoch struct.
     * @param value_: the epoch value.
     */
    function set(Epoch storage self_, uint32 value_) internal {
        self_._value = value_;
    }

    /***
     * @dev gets the latest epoch value stored in the Epoch struct.
     * @return the latest epoch value stored in the Epoch struct.
     */
    function get(Epoch storage self_) internal view returns (uint32) {
        return self_._value;
    }
}

abstract contract SnapshotRingBuffer {
    using RingBuffer for SnapshotBuffer;
    using EpochLib for Epoch;

    /**
     * @notice Assigns the snapshot to correct index and updates __epoch
     * @param snapshot_ to be stored
     * @return epoch of the passed snapshot
     */
    function _setSnapshot(Snapshot memory snapshot_) internal returns (uint32) {
        uint32 epoch = _getSnapshots().set(_getEpochFromHeight, snapshot_);
        _epochRegister().set(epoch);
        return epoch;
    }

    /**
     * @notice Returns the snapshot for the passed epoch
     * @param epoch_ of the snapshot
     */
    function _getSnapshot(uint32 epoch_) internal view returns (Snapshot memory snapshot) {
        if (epoch_ == 0) {
            return Snapshot(0, BClaimsParserLibrary.BClaims(0, 0, 0, 0, 0, 0, 0));
        }
        //get the pointer to the specified epoch snapshot
        Snapshot memory snapshot_ = _getSnapshots().get(epoch_);
        if (_getEpochFromHeight(snapshot_.blockClaims.height) != epoch_) {
            revert SnapshotsErrors.SnapshotsNotInBuffer(epoch_);
        }
        return snapshot_;
    }

    /***
     * @dev: gets the latest snapshot stored in the ring buffer.
     * @return ok if the struct is valid and the snapshot struct itself
     */
    function _getLatestSnapshot() internal view returns (Snapshot memory snapshot) {
        return _getSnapshot(_epochRegister().get());
    }

    // Must be defined in storage contract
    function _getEpochFromHeight(uint32) internal view virtual returns (uint32);

    // Must be defined in storage contract
    function _getSnapshots() internal view virtual returns (SnapshotBuffer storage);

    // Must be defined in storage contract
    function _epochRegister() internal view virtual returns (Epoch storage);
}