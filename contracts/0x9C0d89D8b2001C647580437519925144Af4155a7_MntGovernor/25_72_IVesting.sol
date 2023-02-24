// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IBuyback.sol";

/**
 * @title Vesting contract provides unlocking of tokens on a schedule. It uses the *graded vesting* way,
 * which unlocks a specific amount of balance every period of time, until all balance unlocked.
 *
 * Vesting Schedule.
 *
 * The schedule of a vesting is described by data structure `VestingSchedule`: starting from the start timestamp
 * throughout the duration, the entire amount of totalAmount tokens will be unlocked.
 */
interface IVesting is IAccessControl {
    /**
     * @notice An event that's emitted when a new vesting schedule for a account is created.
     */
    event VestingScheduleAdded(address target, VestingSchedule schedule);

    /**
     * @notice An event that's emitted when a vesting schedule revoked.
     */
    event VestingScheduleRevoked(address target, uint256 unreleased, uint256 locked);

    /**
     * @notice An event that's emitted when the account Withdrawn the released tokens.
     */
    event Withdrawn(address target, uint256 withdrawn);

    /**
     * @notice Emitted when an account is added to the delay list
     */
    event AddedToDelayList(address account);

    /**
     * @notice Emitted when an account is removed from the delay list
     */
    event RemovedFromDelayList(address account);

    /**
     * @notice The structure is used in the contract constructor for create vesting schedules
     * during contract deploying.
     * @param totalAmount the number of tokens to be vested during the vesting duration.
     * @param target the address that will receive tokens according to schedule parameters.
     * @param start offset in minutes at which vesting starts. Zero will vesting immediately.
     * @param duration duration in minutes of the period in which the tokens will vest.
     * @param revocable whether the vesting is revocable or not.
     */
    struct ScheduleData {
        uint256 totalAmount;
        address target;
        uint32 start;
        uint32 duration;
        bool revocable;
    }

    /**
     * @notice Vesting schedules of an account.
     * @param totalAmount the number of tokens to be vested during the vesting duration.
     * @param released the amount of the token released. It means that the account has called withdraw() and received
     * @param start the timestamp in minutes at which vesting starts. Must not be equal to zero, as it is used to
     * check for the existence of a vesting schedule.
     * @param duration duration in minutes of the period in which the tokens will vest.
     * `released amount` of tokens to his address.
     * @param revocable whether the vesting is revocable or not.
     */
    struct VestingSchedule {
        uint256 totalAmount;
        uint256 released;
        uint32 created;
        uint32 start;
        uint32 duration;
        bool revocable;
    }

    /// @notice get keccak-256 hash of GATEKEEPER role
    function GATEKEEPER() external view returns (bytes32);

    /// @notice get keccak-256 hash of TOKEN_PROVIDER role
    function TOKEN_PROVIDER() external view returns (bytes32);

    /**
     * @notice get vesting schedule of an account.
     */
    function schedules(address)
        external
        view
        returns (
            uint256 totalAmount,
            uint256 released,
            uint32 created,
            uint32 start,
            uint32 duration,
            bool revocable
        );

    /**
     * @notice Gets the amount of MNT that was transferred to Vesting contract
     * and can be transferred to other accounts via vesting process.
     * Transferring rewards from Vesting via withdraw method will decrease this amount.
     */
    function allocation() external view returns (uint256);

    /**
     * @notice Gets the amount of allocated MNT tokens that are not used in any vesting schedule yet.
     * Creation of new vesting schedules will decrease this amount.
     */
    function freeAllocation() external view returns (uint256);

    /**
     * @notice get Whether or not the account is in the delay list
     */
    function delayList(address) external view returns (bool);

    /**
     * @notice Withdraw the specified number of tokens. For a successful transaction, the requirement
     * `amount_ > 0 && amount_ <= unreleased` must be met.
     * If `amount_ == MaxUint256` withdraw all unreleased tokens.
     * @param amount_ The number of tokens to withdraw.
     */
    function withdraw(uint256 amount_) external;

    /**
     * @notice Increases vesting schedule allocation and transfers MNT into Vesting.
     * @dev RESTRICTION: TOKEN_PROVIDER only
     */
    function refill(uint256 amount) external;

    /**
     * @notice Transfers MNT that were added to the contract without calling the refill and are unallocated.
     * @dev RESTRICTION: Admin only
     */
    function sweep(address recipient, uint256 amount) external;

    /**
     * @notice Allows the admin to create a new vesting schedules.
     * @param schedulesData an array of vesting schedules that will be created.
     * @dev RESTRICTION: Admin only.
     */
    function createVestingScheduleBatch(ScheduleData[] memory schedulesData) external;

    /**
     * @notice Allows the admin to revoke the vesting schedule. Tokens already vested
     * transfer to the account, the rest are returned to the vesting contract.
     * Accounts that are in delay list have their withdraw blocked so they would not receive anything.
     * @param target_ the address from which the vesting schedule is revoked.
     * @dev RESTRICTION: Gatekeeper only.
     */
    function revokeVestingSchedule(address target_) external;

    /**
     * @notice Calculates the end of the vesting.
     * @param who_ account address for which the parameter is returned.
     * @return the end of the vesting.
     */
    function endOfVesting(address who_) external view returns (uint256);

    /**
     * @notice Calculates locked amount for a given `time`.
     * @param who_ account address for which the parameter is returned.
     * @return locked amount for a given `time`.
     */
    function lockedAmount(address who_) external view returns (uint256);

    /**
     * @notice Calculates the amount that has already vested.
     * @param who_ account address for which the parameter is returned.
     * @return the amount that has already vested.
     */
    function vestedAmount(address who_) external view returns (uint256);

    /**
     * @notice Calculates the amount that has already vested but hasn't been released yet.
     * @param who_ account address for which the parameter is returned.
     * @return the amount that has already vested but hasn't been released yet.
     */
    function releasableAmount(address who_) external view returns (uint256);

    /**
     * @notice Gets the amount that has already vested but hasn't been released yet if account
     *      schedule had no starting delay (cliff).
     */
    function getReleasableWithoutCliff(address account) external view returns (uint256);

    /**
     * @notice Add an account with revocable schedule to the delay list
     * @param who_ The account that is being added to the delay list
     * @dev RESTRICTION: Gatekeeper only.
     */
    function addToDelayList(address who_) external;

    /**
     * @notice Remove an account from the delay list
     * @param who_ The account that is being removed from the delay list
     * @dev RESTRICTION: Gatekeeper only.
     */
    function removeFromDelayList(address who_) external;
}