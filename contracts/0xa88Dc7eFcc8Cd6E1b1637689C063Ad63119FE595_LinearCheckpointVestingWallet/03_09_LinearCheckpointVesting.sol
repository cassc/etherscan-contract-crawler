// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

/**
 * @title LinearCheckpointVesting
 * @dev Implements a vesting schedule that linearly releases chunks of the vested amount according to a schedule given
 *  by checkpoints (as timestamps). At each checkpoint, (total amount) / (number of checkpoints) is released.
 */
abstract contract LinearCheckpointVesting {

    /**
     * @dev The timestamps (in seconds) at which chunks of the vested amount are released.
     */
    uint64[] private _checkpoints;

    /**
     * @dev Sets the checkpoint timestamps.
     * @param checkpointTimestamps A list of UNIX timestamps, sorted ascending.
     */
    constructor(uint64[] memory checkpointTimestamps) {
        require(checkpointTimestamps.length > 0, "Checkpoints must not be empty");
        // For the calculations in checkpointVestingSchedule to work the timestamps have to be sorted ascending.
        for (uint i = 0; i < checkpointTimestamps.length - 1; i++) {
            require(checkpointTimestamps[i] < checkpointTimestamps[i + 1], "Checkpoints must be sorted ascending");
        }
        _checkpoints = checkpointTimestamps;
    }

    /**
     * @dev Getter for the checkpoints
     */
    function checkpoints() public view returns (uint64[] memory) {
        return _checkpoints;
    }

    /**
     * @dev Implements a checkpointed vesting schedule.
     * @param totalAllocation The total allocation for the vesting
     * @param timestamp The current timestamp
     */
    function checkpointVestingSchedule(
        uint256 totalAllocation,
        uint64 timestamp
    ) internal view returns (uint256) {
        // Use a copy of the state variable as this safes gas costs
        uint64[] memory checkpointsCopy = _checkpoints;
        if (timestamp < checkpointsCopy[0]) {
            // If the vesting hasn't started yet, return 0
            return 0;
        } else if (timestamp >= checkpointsCopy[_checkpoints.length - 1]) {
            // If the final timestamp has been reached, return everything
            return totalAllocation;
        } else {
            // Find out what checkpoint we are currently at
            uint currentCheckpoint = 0;
            for (uint i = 0; i < checkpointsCopy.length; i++) {
                // Find the first checkpoint we haven't reached yet, its index is the amount of passed checkpoints
                if (timestamp < checkpointsCopy[i]) {
                    currentCheckpoint = i;
                    break;
                }
            }
            // We can ignore rounding here. The full allocation will always be accessible after
            // the duration has been exceeded.
            // Do the division first to avoid integer overflows in extreme situations. This will add
            // some more possibility for rounding errors, but with a low number of checkpoints that
            // does not matter.
            return (totalAllocation / checkpointsCopy.length) * currentCheckpoint;
        }
    }
}