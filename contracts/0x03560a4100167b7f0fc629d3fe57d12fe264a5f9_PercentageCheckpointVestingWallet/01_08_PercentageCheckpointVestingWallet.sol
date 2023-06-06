// SPDX-License-Identifier: UNLICENSED
import "../openzeppelin-contracts/contracts/finance/VestingWallet.sol";
pragma solidity 0.8.5;

/**
 * @title PercentageCheckpointVestingWallet
 *
 * @dev Implements a vesting wallet that allows access to "chunks" of the vested amount at configurable checkpoints. At
 * each checkpoint a percentage of the remaining allocation is released. After the final checkpoint the remaining
 * vested amount is released.
 */
contract PercentageCheckpointVestingWallet is VestingWallet {

    /**
     * @dev The timestamps (in seconds) at which chunks of the vested amount are released.
     */
    uint64[] private _checkpoints;

    /**
     * @dev The percentage of the the remaining allocation to release at each chunk, given as a number
     * between 1 - 100.
     */
    uint private immutable _percentage;

    /**
     * @dev Validates the {checkpointTimestamps} and {percentage} parameters then sets them
     * @param beneficiaryAddress The address that will be allowed to release tokens from this
     *  contract
     * @param checkpointTimestamps The vesting schedule in UNIX seconds. Chunks of the vested amount
     *  will be available at each checkpoint. The checkpoints _must_ be ordered ascending.
     * @param percentage The percentage of the remaining allocation to release at each chunk
     */
    constructor(address beneficiaryAddress, uint64[] memory checkpointTimestamps, uint percentage) VestingWallet(
        beneficiaryAddress,
        checkpointTimestamps[0],
        checkpointTimestamps[checkpointTimestamps.length - 1] - checkpointTimestamps[0]
    ) {
        for (uint i = 0; i < checkpointTimestamps.length - 1; i++) {
            require(checkpointTimestamps[i] < checkpointTimestamps[i + 1], "Checkpoints must be sorted ascending");
        }
        require(percentage != 0 && percentage < 100, "Percentage must be between 1 and 99");
        _checkpoints = checkpointTimestamps;
        _percentage = percentage;
    }

    /**
     * Returns the timestamps at which chunks can be released.
     */
    function checkpoints() external view returns (uint64[] memory) {
        return _checkpoints;
    }

    function _vestingSchedule(uint256 totalAllocation, uint64 timestamp) override internal view returns (uint256) {
        if (timestamp < start()) {
            // If the vesting hasn't started yet, return 0
            return 0;
        } else if (timestamp >= start() + duration()) {
            // If the final timestamp has been reached, return everything
            return totalAllocation;
        } else {
            // Use a copy of the state variable as this safes gas costs
            uint64[] memory checkpointsCopy = _checkpoints;
            // The following inductive algorithm to calculate the releasable amount is used:
            // Given a list of timestamps at which a new part of the allocation is releasable, at
            // each timestamp a fixed percentage of the remaining allocation are to be released.
            // After the last timestamp the rest is released
            //
            // The algorithm represents the _total_ amount releasable at the given timestamp, not
            // the releasable amount of the current chunk.
            // a_0 = 0
            // a_(n + 1) = a_n + (totalAllocation - a_n) * percentage
            uint256 allocation = 0;
            for (uint i = 0; i < checkpointsCopy.length; i++) {
                if (timestamp < checkpointsCopy[i]) {
                    // If the timestamp is smaller than the next checkpoint we have reached the
                    // current checkpoint and can abort
                    break;
                }
                // While not aborted, calculate the next value
                allocation = allocation + (totalAllocation - allocation) * _percentage / 100;
            }
            return allocation;
        }
    }
}