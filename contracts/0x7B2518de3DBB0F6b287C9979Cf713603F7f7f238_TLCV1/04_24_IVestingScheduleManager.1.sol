//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../state/tlc/VestingSchedules.sol";

/// @title Vesting Schedules Interface (v1)
/// @author Alluvial
/// @notice This interface exposes methods to manage vestings
interface IVestingScheduleManagerV1 {
    /// @notice A new vesting schedule has been created
    /// @param index Vesting schedule index
    /// @param creator Creator of the vesting schedule
    /// @param beneficiary Vesting beneficiary address
    /// @param amount Vesting schedule amount
    event CreatedVestingSchedule(uint256 index, address indexed creator, address indexed beneficiary, uint256 amount);

    /// @notice Vesting schedule has been released
    /// @param index Vesting schedule index
    /// @param releasedAmount Amount of tokens released to the beneficiary
    event ReleasedVestingSchedule(uint256 index, uint256 releasedAmount);

    /// @notice Vesting schedule has been revoked
    /// @param index Vesting schedule index
    /// @param returnedAmount Amount of tokens returned to the creator
    event RevokedVestingSchedule(uint256 index, uint256 returnedAmount);

    /// @notice Vesting escrow has been delegated
    /// @param index Vesting schedule index
    /// @param oldDelegatee old delegatee
    /// @param newDelegatee new delegatee
    event DelegatedVestingEscrow(uint256 index, address oldDelegatee, address newDelegatee);

    /// @notice Vesting schedule creator has unsufficient balance to create vesting schedule
    error UnsufficientVestingScheduleCreatorBalance();

    /// @notice Invalid parameter for a vesting schedule
    error InvalidVestingScheduleParameter(string msg);

    /// @notice Attempt to revoke a schedule in the past
    error VestingScheduleNotRevocableInPast();

    /// @notice The vesting schedule is not revocable
    error VestingScheduleNotRevocable();

    /// @notice The vesting schedule is locked
    error VestingScheduleIsLocked();

    /// @notice Attempt to revoke at a
    error InvalidRevokedVestingScheduleEnd();

    /// @notice No token to release
    error ZeroReleasableAmount();

    /// @notice Get vesting schedule
    /// @param _index Index of the vesting schedule
    function getVestingSchedule(uint256 _index) external view returns (VestingSchedules.VestingSchedule memory);

    /// @notice Get count of vesting schedules
    /// @return count of vesting schedules
    function getVestingScheduleCount() external view returns (uint256);

    /// @notice Get the address of the escrow for a vesting schedule
    /// @param _index Index of the vesting schedule
    /// @return address of the escrow
    function vestingEscrow(uint256 _index) external view returns (address);

    /// @notice Computes the releasable amount of tokens for a vesting schedule.
    /// @param _index index of the vesting schedule
    /// @return amount of releasable tokens
    function computeVestingReleasableAmount(uint256 _index) external view returns (uint256);

    /// @notice Computes the vested amount of tokens for a vesting schedule.
    /// @param _index index of the vesting schedule
    /// @return amount of vested tokens
    function computeVestingVestedAmount(uint256 _index) external view returns (uint256);

    /// @notice Creates a new vesting schedule
    /// @param _beneficiary address of the beneficiary of the tokens
    /// @param _start start time of the vesting
    /// @param _cliffDuration duration to vesting cliff (in seconds)
    /// @param _duration total vesting schedule duration after which all tokens are vested (in seconds)
    /// @param _period duration of a period after which new tokens unlock (in seconds)
    /// @param _lockDuration duration during which tokens are locked (in seconds)
    /// @param _revocable whether the vesting schedule is revocable or not
    /// @param _amount amount of token attributed by the vesting schedule
    /// @param _delegatee address to delegate escrow voting power to
    /// @return index of the created vesting schedule
    function createVestingSchedule(
        uint64 _start,
        uint32 _cliffDuration,
        uint32 _duration,
        uint32 _period,
        uint32 _lockDuration,
        bool _revocable,
        uint256 _amount,
        address _beneficiary,
        address _delegatee
    ) external returns (uint256);

    /// @notice Revoke vesting schedule
    /// @param _index Index of the vesting schedule to revoke
    /// @param _end End date for the schedule
    /// @return returnedAmount amount returned to the vesting schedule creator
    function revokeVestingSchedule(uint256 _index, uint64 _end) external returns (uint256 returnedAmount);

    /// @notice Release vesting schedule
    /// @param _index Index of the vesting schedule to release
    /// @return released amount
    function releaseVestingSchedule(uint256 _index) external returns (uint256);

    /// @notice Delegate vesting escrowed tokens
    /// @param _index index of the vesting schedule
    /// @param _delegatee address to delegate the token to
    function delegateVestingEscrow(uint256 _index, address _delegatee) external returns (bool);
}