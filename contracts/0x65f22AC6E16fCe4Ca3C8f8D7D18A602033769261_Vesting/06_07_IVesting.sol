// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

/**
 * @title An interface for the Vesting contract.
 * @author Asymetrix Protocol Inc Team
 * @notice An interface that describes data structures and events for the
 *         Vesting contract.
 */
interface IVesting {
    /**
     * @notice Vesting schedule structure.
     * @param amount An amount of ASX tokens to vest.
     * @param released An amount of ASX tokens that already were released.
     * @param owner An owner of a vesting schedule.
     * @param startTimestamp A timestamp when a vesting schedule started.
     * @param lockPeriod A lock period duration (in seconds) that should have
     *                   place before distribution will start.
     * @param releasePeriod A period (in seconds) during wich ASX tokens will
     *                      be distributed after the lock period.
     */
    struct VestingSchedule {
        uint256 amount;
        uint256 released;
        address owner;
        uint32 startTimestamp;
        uint32 lockPeriod;
        uint32 releasePeriod;
    }

    /**
     * @notice Event emitted when vesting schedule was created.
     * @param vestingSchedule A newly created vesting schedule object.
     */
    event VestingScheduleCreated(VestingSchedule vestingSchedule);

    /**
     * @notice Event emitted when a part of ASX tokens from a vesting schedule
     *         was released.
     * @param vsid An ID of a vesting schedule.
     * @param recipient An address of ASX tokens recipient.
     * @param amount An amount of tokens that were released.
     */
    event Released(
        uint256 indexed vsid,
        address indexed recipient,
        uint256 amount
    );

    /**
     * @notice Event emitted when a part of unused ASX tokens or other tokens
     *         (including ETH) was withdrawn by an owner.
     * @param token A token that was withdraw. If token address was equal to
     *              zero address - ETH were withdrawn.
     * @param owner An address of an owner that withdrawn unused tokens.
     * @param amount An amount of tokens that were withdrawn.
     */
    event Withdrawn(
        address indexed token,
        address indexed owner,
        uint256 amount
    );
}