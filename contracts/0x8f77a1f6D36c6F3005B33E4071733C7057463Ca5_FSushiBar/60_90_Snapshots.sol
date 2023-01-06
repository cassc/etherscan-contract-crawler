// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

library Snapshots {
    error InvalidTimestamp();

    struct Snapshot {
        uint256 value;
        uint256 timestamp;
    }

    function size(Snapshot[] storage snapshots) internal view returns (uint256) {
        return snapshots.length;
    }

    function lastValue(Snapshot[] storage snapshots) internal view returns (uint256) {
        uint256 _length = snapshots.length;
        return _length > 0 ? snapshots[_length - 1].value : 0;
    }

    function valueAt(Snapshot[] storage snapshots, uint256 timestamp) internal view returns (uint256) {
        uint256 _now = block.timestamp;
        if (_now < timestamp) revert InvalidTimestamp();

        uint256 _length = snapshots.length;
        if (_length == 0) {
            return 0;
        }

        // First check most recent balance
        if (snapshots[_length - 1].timestamp <= timestamp) {
            return snapshots[_length - 1].value;
        }

        // Next check implicit zero balance
        if (timestamp < snapshots[0].timestamp) {
            return 0;
        }

        unchecked {
            uint256 lower = 0;
            uint256 upper = _length - 1;
            while (upper > lower) {
                uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
                Snapshot memory snapshot = snapshots[center];
                if (snapshot.timestamp == _now) {
                    return snapshot.value;
                } else if (snapshot.timestamp < _now) {
                    lower = center;
                } else {
                    upper = center - 1;
                }
            }
            return snapshots[lower].value;
        }
    }

    function append(Snapshot[] storage snapshots, uint256 value) internal {
        snapshots.push(Snapshot(value, block.timestamp));
    }
}