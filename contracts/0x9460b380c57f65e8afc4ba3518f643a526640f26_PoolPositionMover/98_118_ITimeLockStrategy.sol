// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";

// ITimeLockStrategy defines an interface for implementing custom time lock strategies.
interface ITimeLockStrategy {
    struct TimeLockStrategyData {
        uint256 minThreshold;
        uint256 midThreshold;
        uint48 minWaitTime;
        uint48 midWaitTime;
        uint48 maxWaitTime;
        uint48 poolPeriodWaitTime;
        uint256 poolPeriodLimit;
        uint256 period;
        uint128 totalAmountInCurrentPeriod;
        uint48 lastResetTimestamp;
    }

    /**
     * @dev Calculates the time lock parameters based on the provided factor params.
     *
     * @param params The TimeLockFactorParams struct containing relevant information to calculate time lock params.
     * @return A TimeLockParams struct containing the calculated time lock parameters.
     */
    function calculateTimeLockParams(
        DataTypes.TimeLockFactorParams calldata params
    ) external returns (DataTypes.TimeLockParams memory);

    function getTimeLockStrategyData()
        external
        view
        returns (TimeLockStrategyData memory);
}