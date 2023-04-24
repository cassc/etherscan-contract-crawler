// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "./interfaces/IDrawCalculatorTimelock.sol";

import "../owner-manager/Manageable.sol";

/**
 * @title  Asymetrix Protocol V1 DrawCalculatorTimelock
 * @author Asymetrix Protocol Inc Team
 * @notice DrawCalculatorTimelock acts as an intermediary between multiple V1
 *         smart contracts. The DrawCalculatorTimelock is responsible for
 *         pushing Draws to a DrawBuffer and routing claim requests from a
 *         PrizeDistributor to a DrawCalculator. The primary objective is to
 *         include a "cooldown" period for all new Draws. Allowing the
 *         correction of a maliciously set Draw in the unfortunate event an
 *         Owner is compromised.
 */
contract DrawCalculatorTimelock is IDrawCalculatorTimelock, Manageable {
    /* ============ Global Variables ============ */

    /// @notice Internal Timelock struct reference.
    Timelock internal timelock;

    /* ============ Events ============ */

    /**
     * @notice Deployed event when the Initialize is called
     */
    event Deployed();

    /* ============ Deploy ============ */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initialize DrawCalculatorTimelockTrigger smart contract.
     * @param _owner Address of the DrawCalculator owner.
     */
    function initialize(address _owner) external initializer {
        __DrawCalculatorTimelock_init_unchained(_owner);
    }

    function __DrawCalculatorTimelock_init_unchained(
        address _owner
    ) internal onlyInitializing {
        __Manageable_init_unchained(_owner);

        emit Deployed();
    }

    /* ============ External Functions ============ */

    /// @inheritdoc IDrawCalculatorTimelock
    function lock(
        uint32 _drawId,
        uint64 _timestamp
    ) external override onlyManagerOrOwner returns (bool) {
        Timelock memory _timelock = timelock;

        require(_drawId == _timelock.drawId + 1, "OM/not-drawid-plus-one");

        _requireTimelockElapsed(_timelock);

        timelock = Timelock({ drawId: _drawId, timestamp: _timestamp });

        emit LockedDraw(_drawId, _timestamp);

        return true;
    }

    /// @inheritdoc IDrawCalculatorTimelock
    function getTimelock() external view override returns (Timelock memory) {
        return timelock;
    }

    /// @inheritdoc IDrawCalculatorTimelock
    function setTimelock(
        Timelock memory _timelock
    ) external override onlyOwner {
        timelock = _timelock;

        emit TimelockSet(_timelock);
    }

    /// @inheritdoc IDrawCalculatorTimelock
    function hasElapsed() external view override returns (bool) {
        return _timelockHasElapsed(timelock);
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Read global DrawCalculator variable.
     * @return IDrawCalculator
     */
    function _timelockHasElapsed(
        Timelock memory _timelock
    ) internal view returns (bool) {
        // If the timelock hasn't been initialized, then it's elapsed
        if (_timelock.timestamp == 0) {
            return true;
        }

        // Otherwise if the timelock has expired, we're good.
        return (block.timestamp > _timelock.timestamp);
    }

    /**
     * @notice Require the timelock "cooldown" period has elapsed
     * @param _timelock the Timelock to check
     */
    function _requireTimelockElapsed(Timelock memory _timelock) internal view {
        require(_timelockHasElapsed(_timelock), "OM/timelock-not-expired");
    }
}