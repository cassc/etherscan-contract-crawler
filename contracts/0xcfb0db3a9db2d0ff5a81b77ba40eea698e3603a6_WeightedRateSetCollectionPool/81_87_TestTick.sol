// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "../Tick.sol";

/**
 * @title Test Contract Wrapper for Tick Library
 * @author MetaStreet Labs
 */
contract TestTick {
    /**
     * @dev External wrapper function for Tick.decode()
     */
    function decode(
        uint128 tick
    ) external pure returns (uint256 limit, uint256 duration, uint256 rate, uint256 reserved) {
        return Tick.decode(tick);
    }

    /**
     * @dev External wrapper function for Tick.validate()
     */
    function validate(uint128 tick, uint256 minLimit, uint256 minDurationIndex) external pure returns (uint256) {
        return Tick.validate(tick, minLimit, minDurationIndex);
    }

    /**
     * @dev External wrapper function for Tick.validate()
     */
    function validate(
        uint128 tick,
        uint256 minLimit,
        uint256 minDurationIndex,
        uint256 maxDurationIndex,
        uint256 minRateIndex,
        uint256 maxRateIndex
    ) external pure {
        return Tick.validate(tick, minLimit, minDurationIndex, maxDurationIndex, minRateIndex, maxRateIndex);
    }
}