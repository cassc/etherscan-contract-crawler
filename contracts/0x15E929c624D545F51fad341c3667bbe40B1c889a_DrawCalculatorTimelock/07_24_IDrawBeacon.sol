// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "./IDrawBuffer.sol";

/**
 * @title  IDrawBeacon
 * @author Asymetrix Protocol Inc Team
 * @notice The DrawBeacon interface.
 */
interface IDrawBeacon {
    /// @notice Draw struct created every draw
    /// @param drawId The monotonically increasing drawId for each draw
    /// @param timestamp Unix timestamp of the draw. Recorded when the draw is
    ///                  created by the DrawBeacon.
    /// @param beaconPeriodStartedAt Unix timestamp of when the draw started
    /// @param beaconPeriodSeconds Unix timestamp of the beacon draw period for
    ///                            this draw.
    /// @param rngRequestInternalId An internal ID of RNG service request.
    /// @param participantsHash A unique hash of participants of the draw.
    /// @param picksNumber A number of picks for the draw.
    /// @param randomness An array of random numbers for the draw.
    /// @param isEmpty A flag that indicates if the draw doesn't have
    ///                participants.
    /// @param paid A flag that indicates if prizes for the draw are paid or not.
    struct Draw {
        uint32 drawId;
        uint64 timestamp;
        uint64 beaconPeriodStartedAt;
        uint32 beaconPeriodSeconds;
        uint32 rngRequestInternalId;
        bytes participantsHash;
        uint256[] randomness;
        uint256 picksNumber;
        bool isEmpty;
        bool paid;
    }

    /**
     * @notice Emit when a new DrawBuffer has been set.
     * @param newDrawBuffer The new DrawBuffer address
     */
    event DrawBufferUpdated(IDrawBuffer indexed newDrawBuffer);

    /**
     * @notice Emit when a draw has opened.
     * @param startedAt Start timestamp
     */
    event BeaconPeriodStarted(uint64 indexed startedAt);

    /**
     * @notice Emit when a draw has started.
     * @param drawId Draw id
     */
    event DrawStarted(uint32 indexed drawId);

    /**
     * @notice Emit when the drawPeriodSeconds is set.
     * @param drawPeriodSeconds Time between draw
     */
    event BeaconPeriodSecondsUpdated(uint32 drawPeriodSeconds);

    /**
     * @notice Returns the number of seconds remaining until the beacon period
     *         can be complete.
     * @return The number of seconds remaining until the beacon period can be
     *         complete.
     */
    function beaconPeriodRemainingSeconds() external view returns (uint64);

    /**
     * @notice Returns beacon period seconds.
     * @return The number of seconds of the beacon period.
     */
    function getBeaconPeriodSeconds() external view returns (uint32);

    /**
     * @notice Returns DrawBuffer contract address.
     * @return DrawBuffer contract address.
     */
    function getDrawBuffer() external view returns (IDrawBuffer);

    /**
     * @notice Returns the time when the beacon period started at.
     * @return The time when the beacon period started at.
     */
    function getBeaconPeriodStartedAt() external view returns (uint64);

    /**
     * @notice Returns the timestamp at which the beacon period ends.
     * @return The timestamp at which the beacon period ends.
     */
    function beaconPeriodEndAt() external view returns (uint64);

    /**
     * @notice Returns the next draw ID.
     * @return The ID of the next draw to start.
     */
    function getNextDrawId() external view returns (uint32);

    /**
     * @notice Calculates the next beacon start time, assuming all beacon
     *         periods have  occurred between the last and now.
     * @return The next beacon period start time.
     */
    function calculateNextBeaconPeriodStartTimeFromCurrentTime()
        external
        view
        returns (uint64);

    /**
     * @notice Calculates when the next beacon period will start.
     * @param time The timestamp to use as the current time.
     * @return The timestamp at which the next beacon period would start.
     */
    function calculateNextBeaconPeriodStartTime(
        uint64 time
    ) external view returns (uint64);

    /**
     * @notice Returns whether the beacon period is over.
     * @return True if the beacon period is over, false otherwise.
     */
    function isBeaconPeriodOver() external view returns (bool);

    /**
     * @notice Returns whether the draw can start
     * @return True if the beacon period is over, false otherwise
     */
    function canStartDraw() external view returns (bool);

    /**
     * @notice Allows the owner to set the beacon period in seconds.
     * @param beaconPeriodSeconds The new beacon period in seconds. Must be
     *        greater than zero.
     */
    function setBeaconPeriodSeconds(uint32 beaconPeriodSeconds) external;

    /**
     * @notice Starts the Draw process. The previous beacon period must have
     *         ended.
     */
    function startDraw() external;

    /**
     * @notice Set global DrawBuffer variable.
     * @dev    All subsequent Draw requests/completions will be pushed to the
     *         new DrawBuffer.
     * @param newDrawBuffer DrawBuffer address
     * @return DrawBuffer
     */
    function setDrawBuffer(
        IDrawBuffer newDrawBuffer
    ) external returns (IDrawBuffer);
}