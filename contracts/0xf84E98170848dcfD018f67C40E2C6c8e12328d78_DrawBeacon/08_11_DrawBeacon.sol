// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../owner-manager/Ownable.sol";

import "./interfaces/IDrawBeacon.sol";
import "./interfaces/IDrawBuffer.sol";

/**
 * @title  Asymetrix Protocol V1 DrawBeacon
 * @author Asymetrix Protocol Inc Team
 * @notice Manages pushing Draws onto DrawBuffer. The DrawBeacon has 1 major
 *         action: creating of a new Draw. A user can create a new Draw using
 *         the startDraw() method which will push the draw onto the DrawBuffer.
 */
contract DrawBeacon is
    Initializable,
    IDrawBeacon,
    Ownable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeCastUpgradeable for uint256;

    /* ============ Variables ============ */

    /// @notice DrawBuffer address
    IDrawBuffer internal drawBuffer;

    /// @notice Seconds between beacon period request
    uint32 internal beaconPeriodSeconds;

    /// @notice Epoch timestamp when beacon period can start
    uint64 internal beaconPeriodStartedAt;

    /**
     * @notice Next Draw ID to use when pushing a Draw onto DrawBuffer
     * @dev Starts at 1. This way we know that no Draw has been recorded at 0.
     */
    uint32 internal nextDrawId;

    /* ============ Events ============ */

    /**
     * @notice Emit when the DrawBeacon is deployed.
     * @param nextDrawId Draw ID at which the DrawBeacon should start. Can't be
     *                   inferior to 1.
     * @param beaconPeriodStartedAt Timestamp when beacon period starts.
     */
    event Deployed(uint32 nextDrawId, uint64 beaconPeriodStartedAt);

    /* ============ Modifiers ============ */

    modifier requireCanStartDraw() {
        require(_isBeaconPeriodOver(), "DrawBeacon/beacon-period-not-over");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /* ============ Initialize ============ */

    /**
     * @notice Deploy the DrawBeacon smart contract.
     * @param _owner Address of the DrawBeacon owner
     * @param _drawBuffer The address of the draw buffer to push draws to
     * @param _nextDrawId Draw ID at which the DrawBeacon should start. Can't be
     *                    inferior to 1.
     * @param _beaconPeriodStart The starting timestamp of the beacon period.
     * @param _beaconPeriodSeconds The duration of the beacon period in seconds
     */
    function initialize(
        address _owner,
        IDrawBuffer _drawBuffer,
        uint32 _nextDrawId,
        uint64 _beaconPeriodStart,
        uint32 _beaconPeriodSeconds
    ) external initializer {
        __DrawBeacon_init_unchained(
            _owner,
            _drawBuffer,
            _nextDrawId,
            _beaconPeriodStart,
            _beaconPeriodSeconds
        );
    }

    function __DrawBeacon_init_unchained(
        address _owner,
        IDrawBuffer _drawBuffer,
        uint32 _nextDrawId,
        uint64 _beaconPeriodStart,
        uint32 _beaconPeriodSeconds
    ) internal onlyInitializing {
        __Ownable_init_unchained(_owner);

        require(
            _beaconPeriodStart > 0,
            "DrawBeacon/beacon-period-greater-than-zero"
        );
        require(_nextDrawId >= 1, "DrawBeacon/next-draw-id-gte-one");

        beaconPeriodStartedAt = _beaconPeriodStart;
        nextDrawId = _nextDrawId;

        _setBeaconPeriodSeconds(_beaconPeriodSeconds);
        _setDrawBuffer(_drawBuffer);

        emit Deployed(_nextDrawId, _beaconPeriodStart);
        emit BeaconPeriodStarted(_beaconPeriodStart);
    }

    /* ============ External Functions ============ */

    /// @inheritdoc IDrawBeacon
    function calculateNextBeaconPeriodStartTimeFromCurrentTime()
        external
        view
        returns (uint64)
    {
        return
            _calculateNextBeaconPeriodStartTime(
                beaconPeriodStartedAt,
                beaconPeriodSeconds,
                _currentTime()
            );
    }

    /// @inheritdoc IDrawBeacon
    function calculateNextBeaconPeriodStartTime(
        uint64 _time
    ) external view override returns (uint64) {
        return
            _calculateNextBeaconPeriodStartTime(
                beaconPeriodStartedAt,
                beaconPeriodSeconds,
                _time
            );
    }

    /// @inheritdoc IDrawBeacon
    function startDraw() external override nonReentrant requireCanStartDraw {
        uint64 _beaconPeriodStartedAt = beaconPeriodStartedAt;
        uint32 _beaconPeriodSeconds = beaconPeriodSeconds;
        uint64 _time = _currentTime();

        // Сreate Draw struct
        IDrawBeacon.Draw memory _draw;

        _draw.drawId = nextDrawId;
        _draw.timestamp = _currentTime();
        _draw.beaconPeriodStartedAt = _beaconPeriodStartedAt;
        _draw.beaconPeriodSeconds = _beaconPeriodSeconds;

        uint32 _drawId = drawBuffer.pushDraw(_draw);

        emit DrawStarted(_drawId);

        /**
         * To avoid clock drift, we should calculate the start time based on the
         * previous period start time.
         */
        uint64 _nextBeaconPeriodStartedAt = _calculateNextBeaconPeriodStartTime(
            _beaconPeriodStartedAt,
            _beaconPeriodSeconds,
            _time
        );

        beaconPeriodStartedAt = _nextBeaconPeriodStartedAt;
        nextDrawId = _drawId + 1;

        emit BeaconPeriodStarted(_nextBeaconPeriodStartedAt);
    }

    /// @inheritdoc IDrawBeacon
    function beaconPeriodRemainingSeconds()
        external
        view
        override
        returns (uint64)
    {
        return _beaconPeriodRemainingSeconds();
    }

    /// @inheritdoc IDrawBeacon
    function beaconPeriodEndAt() external view override returns (uint64) {
        return _beaconPeriodEndAt();
    }

    /// @inheritdoc IDrawBeacon
    function getBeaconPeriodSeconds() external view returns (uint32) {
        return beaconPeriodSeconds;
    }

    /// @inheritdoc IDrawBeacon
    function getBeaconPeriodStartedAt() external view returns (uint64) {
        return beaconPeriodStartedAt;
    }

    /// @inheritdoc IDrawBeacon
    function getDrawBuffer() external view returns (IDrawBuffer) {
        return drawBuffer;
    }

    /// @inheritdoc IDrawBeacon
    function getNextDrawId() external view returns (uint32) {
        return nextDrawId;
    }

    /// @inheritdoc IDrawBeacon
    function isBeaconPeriodOver() external view override returns (bool) {
        return _isBeaconPeriodOver();
    }

    /// @inheritdoc IDrawBeacon
    function canStartDraw() external view override returns (bool) {
        return _isBeaconPeriodOver();
    }

    /// @inheritdoc IDrawBeacon
    function setDrawBuffer(
        IDrawBuffer newDrawBuffer
    ) external override onlyOwner returns (IDrawBuffer) {
        return _setDrawBuffer(newDrawBuffer);
    }

    /// @inheritdoc IDrawBeacon
    function setBeaconPeriodSeconds(
        uint32 _beaconPeriodSeconds
    ) external override onlyOwner {
        _setBeaconPeriodSeconds(_beaconPeriodSeconds);
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Calculates when the next beacon period will start.
     * @param _beaconPeriodStartedAt The timestamp at which the beacon period
     *                               started.
     * @param _beaconPeriodSeconds The duration of the beacon period in seconds.
     * @param _time The timestamp to use as the current time.
     * @return The timestamp at which the next beacon period would start.
     */
    function _calculateNextBeaconPeriodStartTime(
        uint64 _beaconPeriodStartedAt,
        uint32 _beaconPeriodSeconds,
        uint64 _time
    ) internal pure returns (uint64) {
        uint64 elapsedPeriods = (_time - _beaconPeriodStartedAt) /
            _beaconPeriodSeconds;

        return _beaconPeriodStartedAt + (elapsedPeriods * _beaconPeriodSeconds);
    }

    /**
     * @notice returns the current time.  Used for testing.
     * @return The current time (block.timestamp)
     */
    function _currentTime() internal view virtual returns (uint64) {
        return uint64(block.timestamp);
    }

    /**
     * @notice Returns the timestamp at which the beacon period ends
     * @return The timestamp at which the beacon period ends
     */
    function _beaconPeriodEndAt() internal view returns (uint64) {
        return beaconPeriodStartedAt + beaconPeriodSeconds;
    }

    /**
     * @notice Returns the number of seconds remaining until the prize can be
     *         awarded.
     * @return The number of seconds remaining until the prize can be awarded.
     */
    function _beaconPeriodRemainingSeconds() internal view returns (uint64) {
        uint64 endAt = _beaconPeriodEndAt();
        uint64 time = _currentTime();

        if (endAt <= time) {
            return 0;
        }

        return endAt - time;
    }

    /**
     * @notice Returns whether the beacon period is over.
     * @return True if the beacon period is over, false otherwise
     */
    function _isBeaconPeriodOver() internal view returns (bool) {
        return _beaconPeriodEndAt() <= _currentTime();
    }

    /**
     * @notice Set global DrawBuffer variable.
     * @dev    All subsequent Draw requests/completions will be pushed to the
     *         new DrawBuffer.
     * @param _newDrawBuffer  DrawBuffer address
     * @return DrawBuffer
     */
    function _setDrawBuffer(
        IDrawBuffer _newDrawBuffer
    ) internal returns (IDrawBuffer) {
        IDrawBuffer _previousDrawBuffer = drawBuffer;

        require(
            address(_newDrawBuffer) != address(0),
            "DrawBeacon/draw-history-not-zero-address"
        );
        require(
            address(_newDrawBuffer) != address(_previousDrawBuffer),
            "DrawBeacon/existing-draw-history-address"
        );

        drawBuffer = _newDrawBuffer;

        emit DrawBufferUpdated(_newDrawBuffer);

        return _newDrawBuffer;
    }

    /**
     * @notice Sets the beacon period in seconds.
     * @param _beaconPeriodSeconds The new beacon period in seconds. Must be
     *                             greater than zero.
     */
    function _setBeaconPeriodSeconds(uint32 _beaconPeriodSeconds) internal {
        require(
            _beaconPeriodSeconds > 0,
            "DrawBeacon/beacon-period-greater-than-zero"
        );

        beaconPeriodSeconds = _beaconPeriodSeconds;

        emit BeaconPeriodSecondsUpdated(_beaconPeriodSeconds);
    }
}