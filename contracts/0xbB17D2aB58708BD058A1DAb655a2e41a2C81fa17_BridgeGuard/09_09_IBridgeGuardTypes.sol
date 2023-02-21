// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

/**
 * @title BridgeGuard contract types
 * @author CloudWalk Inc.
 */
interface IBridgeGuardTypes {
    /// @dev The structure with data for bridge guard details.
    struct Guard {
        uint256 timeFrame;      // The time frame to track the accommodation amount cap.
        uint256 volumeLimit;    // The maximum amount of tokens that can be accommodated in a time frame.
        uint256 lastResetTime;  // The last timestamp of volume reset.
        uint256 currentVolume;  // The amount of accommodated tokens in the current time frame.
    }

    /// @dev The enumeration of possible validation errors.
    enum ValidationError {
        NO_ERROR,               // 0 No error
        TIME_FRAME_NOT_SET,     // 1 Time frame not set
        VOLUME_LIMIT_REACHED    // 2 Volume limit reached
    }
}