// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import {SafeCastLib} from "solmate/utils/SafeCastLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import {IUniswapV3PoolDerivedState} from "v3-core/interfaces/pool/IUniswapV3PoolDerivedState.sol";

/// @title Uniswap v3 Price-out-of-range Oracle
/// @author zefram.eth
/// @notice Flashloan-proof Uniswap v3 price-out-of-range oracle for querying if a position is out of range onchain
/// @dev Allows anyone to take a recording of a position over a time window to see for what proportion of the window
/// was the position in range. If the proportion is above the threshold (set at deploy-time) then it's state becomes
/// IN_RANGE, otherwise it becomes OUT_OF_RANGE.
contract UniswapPoorOracle {
    /// -----------------------------------------------------------------------
    /// Library usage
    /// -----------------------------------------------------------------------

    using SafeCastLib for uint256;
    using FixedPointMathLib for uint256;

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    /// @notice Thrown when trying to finish a recording when there is no recording or
    /// the length of the recording is invalid.
    error UniswapPoorOracle__NoValidRecording();

    /// @notice Thrown when trying to start a recording for a position when there's already
    /// one in progress.
    error UniswapPoorOracle__RecordingAlreadyInProgress();

    /// -----------------------------------------------------------------------
    /// Enums
    /// -----------------------------------------------------------------------

    /// @notice The in-range state of a position.
    /// - UNKNOWN means a recording has never been taken.
    /// - IN_RANGE means it was in range at the time of the last recording.
    /// - OUT_OF_RANGE means it was out of range at the time of the last recording.
    enum PositionState {
        UNKNOWN,
        IN_RANGE,
        OUT_OF_RANGE
    }

    /// -----------------------------------------------------------------------
    /// Structs
    /// -----------------------------------------------------------------------

    /// @notice The state of a recording.
    /// @param startTime The Unix timestamp when the recording was started, in seconds.
    /// @param startSecondsInside The secondsInside value of the position at the start of the recording.
    struct RecordingState {
        uint64 startTime;
        uint32 startSecondsInside;
    }

    /// -----------------------------------------------------------------------
    /// Immutable parameters
    /// -----------------------------------------------------------------------

    /// @notice The threshold for determining whether a position is in range.
    /// Scaled by 1e18. Should be a value between 0 and 1e18.
    uint256 public immutable inRangeThreshold;

    /// @notice The minimum length of a valid recording, in seconds.
    /// @dev The larger it is, the more secure the resulting state is (in the sense that
    /// it's expensive to manipulate), but the more time a recording takes. In addition, a
    /// longer recording is less useful after a point, since the normal volatility of the
    /// assets in the pool would come into play and affect the result. Should in general be
    /// somewhere between 30 minutes and 24 hours.
    uint256 public immutable recordingMinLength;

    /// @notice The maximum length of a valid recording, in seconds.
    /// @dev Prevents recordings that are so long that the normal volatility of the assets
    /// in the pool come into play.
    uint256 public immutable recordingMaxLength;

    /// -----------------------------------------------------------------------
    /// State variables
    /// -----------------------------------------------------------------------

    /// @dev The current in-range state of a position. Keyed by getPositionKey().
    mapping(bytes32 => PositionState) internal _positionState;

    /// @dev The state of a recording. Recordings are deleted after they are finished.
    /// Keyed by getPositionKey().
    mapping(bytes32 => RecordingState) internal _recordingState;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(uint256 inRangeThreshold_, uint256 recordingMinLength_, uint256 recordingMaxLength_) {
        inRangeThreshold = inRangeThreshold_;
        recordingMinLength = recordingMinLength_;
        recordingMaxLength = recordingMaxLength_;
    }

    /// -----------------------------------------------------------------------
    /// User actions
    /// -----------------------------------------------------------------------

    /// @notice Starts a new recording. Will revert if either tickLower or tickUpper hasn't been
    /// initialized in the Uniswap pool (which wouldn't be the case if a position [tickLower, tickUpper]
    /// exists).
    /// @dev If a recording already exists for the position but it's length is more than the maximum,
    /// it simply gets overwritten.
    /// @param pool The Uniswap V3 pool
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    function startRecording(address pool, int24 tickLower, int24 tickUpper) external {
        bytes32 key = getPositionKey(pool, tickLower, tickUpper);

        // ensure no active recording is in progress
        {
            uint256 startTime = _recordingState[key].startTime;
            if (startTime != 0 && block.timestamp - startTime <= recordingMaxLength) {
                revert UniswapPoorOracle__RecordingAlreadyInProgress();
            }
        }

        // query uniswap pool
        (,, uint32 secondsInside) = IUniswapV3PoolDerivedState(pool).snapshotCumulativesInside(tickLower, tickUpper);

        // create new recording
        _recordingState[key] =
            RecordingState({startTime: block.timestamp.safeCastTo64(), startSecondsInside: secondsInside});
    }

    /// @notice Finishes a recording and returns the resulting in-range state of the position.
    /// @param pool The Uniswap V3 pool
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @return state The resulting state of the position
    function finishRecording(address pool, int24 tickLower, int24 tickUpper) external returns (PositionState state) {
        bytes32 key = getPositionKey(pool, tickLower, tickUpper);

        RecordingState memory recording = _recordingState[key];

        // ensure there is a valid recording
        uint256 recordingLength = block.timestamp - recording.startTime;
        if (
            !(recording.startTime != 0 && recordingLength >= recordingMinLength && recordingLength <= recordingMaxLength)
        ) {
            revert UniswapPoorOracle__NoValidRecording();
        }

        // query uniswap pool
        (,, uint256 secondsInside) = IUniswapV3PoolDerivedState(pool).snapshotCumulativesInside(tickLower, tickUpper);
        uint256 proportionInRange = (secondsInside - recording.startSecondsInside).divWadDown(recordingLength);

        // update position state
        state = proportionInRange >= inRangeThreshold ? PositionState.IN_RANGE : PositionState.OUT_OF_RANGE;
        _positionState[key] = state;

        // delete recording
        delete _recordingState[key];
    }

    /// -----------------------------------------------------------------------
    /// View functions
    /// -----------------------------------------------------------------------

    /// @notice Returns the in-range state of a position based on the last recording
    /// taken.
    /// @param pool The Uniswap V3 pool
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @return state The current state of the position
    function getPositionState(address pool, int24 tickLower, int24 tickUpper)
        external
        view
        returns (PositionState state)
    {
        return _positionState[getPositionKey(pool, tickLower, tickUpper)];
    }

    /// @notice Returns the in-range state of a position based on the last recording
    /// taken, using the position's key as input.
    /// @param key The key of the position as computed by getPositionKey()
    /// @return state The current state of the position
    function getPositionStateFromKey(bytes32 key) external view returns (PositionState state) {
        return _positionState[key];
    }

    /// @notice Computes the key of a position used by _positionState and _recordingState.
    /// @param pool The Uniswap V3 pool
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @return The key of the position
    function getPositionKey(address pool, int24 tickLower, int24 tickUpper) public pure returns (bytes32) {
        return keccak256(abi.encode(pool, tickLower, tickUpper));
    }
}