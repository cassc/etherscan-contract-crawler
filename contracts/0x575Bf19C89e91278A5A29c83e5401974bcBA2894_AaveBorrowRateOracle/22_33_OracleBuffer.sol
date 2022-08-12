// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.9;

/// @title OracleBuffer
/// @notice Provides the value history needed by multiple oracle contracts
/// @dev Instances of stored oracle data, "observations", are collected in the oracle array
/// Every pool is initialized with an oracle array length of 1. Anyone can pay the SSTOREs to increase the
/// maximum length of the oracle array. New slots will be added when the array is fully populated.
/// Observations are overwritten when the full length of the oracle array is populated.
/// The most recent observation is available, independent of the length of the oracle array, by passing 0 to observe()
library OracleBuffer {
    uint256 public constant MAX_BUFFER_LENGTH = 65535;

    /// @dev An Observation fits in one storage slot, keeping gas costs down and allowing `grow()` to pre-pay for gas
    struct Observation {
        // The timesamp in seconds. uint32 allows tiemstamps up to the year 2105. Future versions may wish to use uint40.
        uint32 blockTimestamp;
        /// @dev Even if observedVale is a decimal with 27 decimal places, this still allows decimal values up to 1.053122916685572e+38
        uint216 observedValue;
        bool initialized;
    }

    /// @notice Creates an observation struct from the current timestamp and observed value
    /// @dev blockTimestamp _must_ be chronologically equal to or greater than last.blockTimestamp, safe for 0 or 1 overflows
    /// @param blockTimestamp The timestamp of the new observation
    /// @param observedValue The observed value (semantics may differ for different types of rate oracle)
    /// @return Observation The newly populated observation
    function observation(uint32 blockTimestamp, uint256 observedValue)
        private
        pure
        returns (Observation memory)
    {
        require(observedValue <= type(uint216).max, ">216");
        return
            Observation({
                blockTimestamp: blockTimestamp,
                observedValue: uint216(observedValue),
                initialized: true
            });
    }

    /// @notice Initialize the oracle array by writing the first slot(s). Called once for the lifecycle of the observations array
    /// @param self The stored oracle array
    /// @param times The times to populate in the Oracle buffe (block.timestamps truncated to uint32)
    /// @param observedValues The observed values to populate in the oracle buffer (semantics may differ for different types of rate oracle)
    /// @return cardinality The number of populated elements in the oracle array
    /// @return cardinalityNext The new length of the oracle array, independent of population
    /// @return rateIndex The index of the most recently populated element of the array
    function initialize(
        Observation[MAX_BUFFER_LENGTH] storage self,
        uint32[] memory times,
        uint256[] memory observedValues
    )
        internal
        returns (
            uint16 cardinality,
            uint16 cardinalityNext,
            uint16 rateIndex
        )
    {
        require(times.length < MAX_BUFFER_LENGTH, "MAXT");
        uint16 length = uint16(times.length);
        require(length == observedValues.length, "Lengths must match");
        require(length > 0, "0T");
        uint32 prevTime = 0;
        for (uint16 i = 0; i < length; i++) {
            require(prevTime < times[i], "input unordered");

            self[i] = observation(times[i], observedValues[i]);
            prevTime = times[i];
        }
        return (length, length, length - 1);
    }

    /// @notice Writes an oracle observation to the array
    /// @dev Writable at most once per block. Index represents the most recently written element. cardinality and index must be tracked externally.
    /// If the index is at the end of the allowable array length (according to cardinality), and the next cardinality
    /// is greater than the current one, cardinality may be increased. This restriction is created to preserve ordering.
    /// @param self The stored oracle array
    /// @param index The index of the observation that was most recently written to the observations array
    /// @param blockTimestamp The timestamp of the new observation
    /// @param observedValue The observed value (semantics may differ for different types of rate oracle)
    /// @param cardinality The number of populated elements in the oracle array
    /// @param cardinalityNext The new length of the oracle array, independent of population
    /// @return indexUpdated The new index of the most recently written element in the oracle array
    /// @return cardinalityUpdated The new cardinality of the oracle array
    function write(
        Observation[MAX_BUFFER_LENGTH] storage self,
        uint16 index,
        uint32 blockTimestamp,
        uint256 observedValue,
        uint16 cardinality,
        uint16 cardinalityNext
    ) internal returns (uint16 indexUpdated, uint16 cardinalityUpdated) {
        Observation memory last = self[index];

        // early return if we've already written an observation this block
        if (last.blockTimestamp == blockTimestamp) return (index, cardinality);

        // if the conditions are right, we can bump the cardinality
        if (cardinalityNext > cardinality && index == (cardinality - 1)) {
            cardinalityUpdated = cardinalityNext;
        } else {
            cardinalityUpdated = cardinality;
        }

        indexUpdated = (index + 1) % cardinalityUpdated;
        self[indexUpdated] = observation(blockTimestamp, observedValue);
    }

    /// @notice Prepares the oracle array to store up to `next` observations
    /// @param self The stored oracle array
    /// @param current The current next cardinality of the oracle array
    /// @param next The proposed next cardinality which will be populated in the oracle array
    /// @return next The next cardinality which will be populated in the oracle array
    function grow(
        Observation[MAX_BUFFER_LENGTH] storage self,
        uint16 current,
        uint16 next
    ) internal returns (uint16) {
        require(current > 0, "I");
        require(next < MAX_BUFFER_LENGTH, "buffer limit");
        // no-op if the passed next value isn't greater than the current next value
        if (next <= current) return current;
        // store in each slot to prevent fresh SSTOREs in swaps
        // this data will not be used because the initialized boolean is still false
        for (uint16 i = current; i < next; i++) self[i].blockTimestamp = 1;
        return next;
    }

    /// @notice Fetches the observations beforeOrAt and atOrAfter a target, i.e. where [beforeOrAt, atOrAfter] is satisfied.
    /// The result may be the same observation, or adjacent observations.
    /// @dev The answer must be contained in the array, used when the target is located within the stored observation
    /// boundaries: older than the most recent observation and younger, or the same age as, the oldest observation
    /// @param self The stored oracle array
    /// @param target The timestamp at which the reserved observation should be for
    /// @param index The index of the observation that was most recently written to the observations array
    /// @param cardinality The number of populated elements in the oracle array
    /// @return beforeOrAt The observation recorded before, or at, the target
    /// @return atOrAfter The observation recorded at, or after, the target
    function binarySearch(
        Observation[MAX_BUFFER_LENGTH] storage self,
        uint32 target,
        uint16 index,
        uint16 cardinality
    )
        internal
        view
        returns (Observation memory beforeOrAt, Observation memory atOrAfter)
    {
        uint256 l = (index + 1) % cardinality; // oldest observation
        uint256 r = l + cardinality - 1; // newest observation
        uint256 i;
        while (true) {
            // i = (l + r) / 2;
            i = (l + r) >> 1;

            beforeOrAt = self[i % cardinality];

            // we've landed on an uninitialized tick, keep searching higher (more recently)
            if (!beforeOrAt.initialized) {
                l = i + 1;
                continue;
            }

            atOrAfter = self[(i + 1) % cardinality];

            bool targetAtOrAfter = beforeOrAt.blockTimestamp <= target;

            // check if we've found the answer!
            if (targetAtOrAfter && target <= atOrAfter.blockTimestamp) break;

            if (!targetAtOrAfter) r = i - 1;
            else l = i + 1;
        }
    }

    /// @notice Fetches the observations beforeOrAt and atOrAfter a given target, i.e. where [beforeOrAt, atOrAfter] is satisfied
    /// @dev Assumes there is at least 1 initialized observation.
    /// Used by observeSingle() to compute the counterfactual accumulator values as of a given block timestamp.
    /// @param self The stored oracle array
    /// @param target The timestamp at which the reserved observation should be for. Must be chronologically before currentTime.
    /// @param currentTime The current timestamp, at which currentValue applies.
    /// @param currentValue The current observed value if we were writing a new observation now (semantics may differ for different types of rate oracle)
    /// @param index The index of the observation that was most recently written to the observations array
    /// @param cardinality The number of populated elements in the oracle array
    /// @return beforeOrAt The observation which occurred at, or before, the given timestamp
    /// @return atOrAfter The observation which occurred at, or after, the given timestamp
    function getSurroundingObservations(
        Observation[MAX_BUFFER_LENGTH] storage self,
        uint32 target,
        uint32 currentTime,
        uint256 currentValue,
        uint16 index,
        uint16 cardinality
    )
        internal
        view
        returns (Observation memory beforeOrAt, Observation memory atOrAfter)
    {
        // optimistically set before to the newest observation
        beforeOrAt = self[index];

        // if the target is chronologically at or after the newest observation, we can early return
        if (beforeOrAt.blockTimestamp <= target) {
            if (beforeOrAt.blockTimestamp == target) {
                // if newest observation equals target, we're in the same block, so we can ignore atOrAfter
                return (beforeOrAt, atOrAfter);
            } else {
                // otherwise, we need to transform
                return (beforeOrAt, observation(currentTime, currentValue));
            }
        }

        // now, set before to the oldest observation
        beforeOrAt = self[(index + 1) % cardinality];
        if (!beforeOrAt.initialized) beforeOrAt = self[0];

        // ensure that the target is chronologically at or after the oldest observation
        require(beforeOrAt.blockTimestamp <= target, "OLD");

        // if we've reached this point, we have to binary search
        return binarySearch(self, target, index, cardinality);
    }
}