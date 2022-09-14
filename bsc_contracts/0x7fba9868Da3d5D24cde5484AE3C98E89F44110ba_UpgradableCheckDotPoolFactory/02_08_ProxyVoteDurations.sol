// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title ProxyVoteDurations
 * @author Jeremy Guyet (@jguyet)
 * @dev Library to manage the duration of the votes.
 */
library ProxyVoteDurations {
    struct VoteDurationSlot {
        uint256 value;
    }

    /**
     * @dev Returns an `VoteDurationSlot` with member `value` located at `slot`.
     */
    function getVoteDurationSlot(bytes32 slot) internal pure returns (VoteDurationSlot storage r) {
        assembly {
            r.slot := slot
        }
    }
}