//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../state/tlc/VestingSchedules.2.sol";

/// @title ERC20 Vestable Votes Upgradeable Interface(v1)
/// @author Alluvial
/// @notice This interface exposes methods to manage vestings
interface IERC20VestableVotesUpgradeableV1 {
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
    /// @param newEnd New end timestamp after revoke action
    event RevokedVestingSchedule(uint256 index, uint256 returnedAmount, uint256 newEnd);

    /// @notice Vesting escrow has been delegated
    /// @param index Vesting schedule index
    /// @param oldDelegatee old delegatee
    /// @param newDelegatee new delegatee
    /// @param beneficiary vesting schedule beneficiary
    event DelegatedVestingEscrow(
        uint256 index, address indexed oldDelegatee, address indexed newDelegatee, address indexed beneficiary
    );

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

    /// @notice Attempt to revoke a vesting schedule with an invalid end parameter
    error InvalidRevokedVestingScheduleEnd();

    /// @notice No token to release
    error ZeroReleasableAmount();

    /// @notice Underflow in global unlock logic (should never happen)
    error GlobalUnlockUnderlfow();

    /// @notice Get vesting schedule
    /// @dev The vesting schedule structure represents a static configuration used to compute the desired
    /// @dev vesting details of a beneficiary at all times. The values won't change even after tokens are released.
    /// @dev The only dynamic field of the structure is end, and is updated whenever a vesting schedule is revoked
    /// @param _index Index of the vesting schedule
    function getVestingSchedule(uint256 _index) external view returns (VestingSchedulesV2.VestingSchedule memory);

    /// @notice Get vesting global unlock schedule activation status for a vesting schedule
    /// @param _index Index of the vesting schedule
    /// @return true if the vesting schedule should ignore the global unlock schedule
    function isGlobalUnlockedScheduleIgnored(uint256 _index) external view returns (bool);

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
    /// @notice There may delay between the time a user should start vesting tokens and the time the vesting schedule is actually created on the contract.
    /// @notice Typically a user joins the Liquid Collective but some weeks pass before the user gets all legal agreements in place and signed for the
    /// @notice token grant emission to happen. In this case, the vesting schedule created for the token grant would start on the join date which is in the past.
    /// @dev As vesting schedules can be created in the past, this means that you should be careful when creating a vesting schedule and what duration parameters
    /// @dev you use as this contract would allow creating a vesting schedule in the past and even a vesting schedule that has already ended.
    /// @param _start start time of the vesting
    /// @param _cliffDuration duration to vesting cliff (in seconds)
    /// @param _duration total vesting schedule duration after which all tokens are vested (in seconds)
    /// @param _periodDuration duration of a period after which new tokens unlock (in seconds)
    /// @param _lockDuration duration during which tokens are locked (in seconds)
    /// @param _revocable whether the vesting schedule is revocable or not
    /// @param _amount amount of token attributed by the vesting schedule
    /// @param _beneficiary address of the beneficiary of the tokens
    /// @param _delegatee address to delegate escrow voting power to
    /// @param _ignoreGlobalUnlockSchedule whether the vesting schedule should ignore the global lock
    /// @return index of the created vesting schedule
    function createVestingSchedule(
        uint64 _start,
        uint32 _cliffDuration,
        uint32 _duration,
        uint32 _periodDuration,
        uint32 _lockDuration,
        bool _revocable,
        uint256 _amount,
        address _beneficiary,
        address _delegatee,
        bool _ignoreGlobalUnlockSchedule
    ) external returns (uint256);

    /// @notice Revoke vesting schedule
    /// @param _index Index of the vesting schedule to revoke
    /// @param _end End date for the schedule
    /// @return returnedAmount amount returned to the vesting schedule creator
    function revokeVestingSchedule(uint256 _index, uint64 _end) external returns (uint256 returnedAmount);

    /// @notice Release vesting schedule
    /// @notice When tokens are released from the escrow, the delegated address of the escrow will see its voting power decrease.
    /// @notice The beneficiary has to make sure its delegation parameters are set properly to be able to use/delegate the voting power of its balance.
    /// @param _index Index of the vesting schedule to release
    /// @return released amount
    function releaseVestingSchedule(uint256 _index) external returns (uint256);

    /// @notice Delegate vesting escrowed tokens
    /// @param _index index of the vesting schedule
    /// @param _delegatee address to delegate the token to
    /// @return True on success
    function delegateVestingEscrow(uint256 _index, address _delegatee) external returns (bool);
}