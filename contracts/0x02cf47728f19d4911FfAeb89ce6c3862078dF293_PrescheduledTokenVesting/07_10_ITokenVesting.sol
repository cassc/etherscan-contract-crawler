// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {ITokenVestingEvents} from "./ITokenVestingEvents.sol";
import {VestingSchedule} from "../defs/VestingSchedule.sol";

interface ITokenVesting is ITokenVestingEvents {
    // - MUTATORS (ADMIN) -
    /**
     * @dev Create a new vesting schedule for a beneficiary. Emit VestingScheduleCreated on success. Multiple vesting
     *      schedules can be created for a beneficiary.
     * @param beneficiary_ Address of the beneficiary to whom vested tokens are transferred.
     * @param start_ Start time of the vesting period. Ref: block.timestamp.
     * @param cliff_ Duration (in seconds) of the cliff in which tokens will begin to vest.
     *               If 0, tokens begin vesting immediately after start_.
     * @param duration_ Duration (in seconds) of the period in which the tokens will vest.
     * @param slicePeriodSeconds_ Duration (in seconds) of a slice period for the vesting.
     * @param revocable_ Whether the vesting is revocable by the contract owner.
     * @param amount_ The total amount of tokens to be released by the end of the vesting schedule.
     *
     * Requirements:
     * - The caller must be the contract owner.
     * - The beneficiary address must be non-zero.
     * - The amount being allocated must
     *   - be a non-zero value
     *   - not exceed the contract's balance of tokens minus all the amounts already allocated to schedules.
     * - The vesting schedule duration must be a non-zero value.
     * - The slice period duration must be a non-zero value.
     * - The cliff cannot exceed the schedule's total duration.
     */
    function createVestingSchedule(
        address beneficiary_,
        uint64 start_,
        uint64 cliff_,
        uint64 duration_,
        uint64 slicePeriodSeconds_,
        uint256 amount_,
        bool revocable_
    ) external;

    /**
     * @dev Revoke the vesting schedule for a given identifier. Emit VestingScheduleCancelled on success.
     *      All vested and non-vested amounts are returned to the contract and can be allocated to
     *      new vesting schedules.
     * @param vestingScheduleId The vesting schedule identifier.
     *
     * Requirements:
     * - The caller must be the contract owner.
     * - The schedule must be revocable.
     * - The schedule must not have been revoked previously.
     */
    function revoke(bytes32 vestingScheduleId) external;

    /**
     * @dev Add time to the duration of a vesting schedule. Emit VestingScheduleExtended on success.
     *
     * Requirements:
     * - The caller must be the contract owner.
     * - The extension must be non-zero.
     * - The schedule must not have been revoked.
     * - The schedule must not have expired.
     */
    function extend(bytes32 vestingScheduleId, uint32 extensionDuration) external;

    /**
     * @dev Withdraw an amount of token. Emit AmountWithdrawn on success.
     * @param amount The amount to withdraw. Must not exceed the amount of tokens not allocated to vesting schedules.
     *
     * Requirements:
     * - The caller must be the contract owner.
     * - The amount must be below (or equal to) the non-allocated token balance.
     */
    function withdraw(uint256 amount) external;

    // - MUTATORS -
    /**
     * @dev Release an amount of vested tokens. Emit AmountReleased on success.
     * @param vestingScheduleId The vesting schedule identifier. 
     * @param amount The amount to release.
     *
     * Requirements:
     * - The caller must be either the contract owner or the vesting schedule beneficiary.
     * - The amount must not exceed the schedule's balance of vested tokens.
     */
    function release(bytes32 vestingScheduleId, uint256 amount) external;

    // - VIEW -
    /**
     * @dev Returns the number of vesting schedules associated to a beneficiary.
     * @return the number of vesting schedules
     */
    function getVestingSchedulesCountByBeneficiary(
        address _beneficiary
    ) external view returns (uint256);

    /**
     * @dev Returns the vesting schedule id at the given index.
     * @return the vesting id
     */
    function getVestingIdAtIndex(uint256 index) external view returns (bytes32);

    /**
     * @notice Returns the vesting schedule information for a given holder and index.
     * @return the vesting schedule structure information
     */
    function getVestingScheduleByAddressAndIndex(
        address holder,
        uint256 index
    ) external view returns (VestingSchedule memory);

    /**
     * @notice Returns the total amount of vesting schedules.
     * @return the total amount of vesting schedules
     */
    function getVestingSchedulesTotalAmount() external view returns (uint256);

    /**
     * @dev Returns the address of the ERC20 token managed by the vesting contract.
     */
    function getToken() external view returns (address);

    /**
     * @dev Returns the number of vesting schedules managed by this contract.
     * @return the number of vesting schedules
     */
    function getVestingSchedulesCount() external view returns (uint256);

    /**
     * @notice Computes the vested amount of tokens for the given vesting schedule identifier.
     * @return the vested amount
     */
    function computeReleasableAmount(bytes32 vestingScheduleId) external view returns (uint256);

    /**
     * @notice Returns the vesting schedule information for a given identifier.
     * @return the vesting schedule structure information
     */
    function getVestingSchedule(
        bytes32 vestingScheduleId
    ) external view returns (VestingSchedule memory);

    /**
     * @dev Returns the amount of tokens that can be withdrawn by the owner.
     * @return the amount of tokens
     */
    function getWithdrawableAmount() external view returns (uint256);

    /**
     * @dev Computes the next vesting schedule identifier for a given holder address.
     */
    function computeNextVestingScheduleIdForHolder(address holder) external view returns (bytes32);

    /**
     * @dev Returns the last vesting schedule for a given holder address.
     */
    function getLastVestingScheduleForHolder(
        address holder
    ) external view returns (VestingSchedule memory);

    /**
     * @dev Computes the vesting schedule identifier for an address and an index.
     */
    function computeVestingScheduleIdForAddressAndIndex(
        address holder,
        uint256 index
    ) external pure returns (bytes32);
}