// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @title TokenVesting
/// @dev This contract allows vesting of an ERC20 token with multiple beneficiary.
/// Each beneficiary can have a different vesting schedule.
/// This implementation uses timestamps, not block numbers.
/// Based on openzeppelin's {VestingWallet}
contract TokenVesting is AccessControl {
    using SafeERC20 for IERC20;

    event NewBeneficiary(
        address indexed beneficiary,
        uint256 totalAllocation,
        uint256 startTimestamp,
        uint256 cliffDuration,
        uint256 duration
    );
    event Released(address indexed beneficiary, uint256 amount);
    event Revoked(address indexed revokee, uint256 amount);

    struct VestingSchedule {
        uint256 totalAllocation;
        uint256 start;
        uint256 cliffDuration;
        uint256 duration;
        uint256 released;
    }

    bytes32 internal constant VESTING_CONTROLLER_ROLE =
        keccak256("VESTING_CONTROLLER_ROLE");

    IERC20 public token;
    mapping(address => VestingSchedule) public vestingSchedules;

    /// @param _token The supported ERC20 token
    constructor(address _token) {
        require(_token != address(0), "Invalid token");
        token = IERC20(_token);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    
    /// @notice Allows members of `VESTING_CONTROLLER_ROLE` to vest tokens
    /// @dev Emits a {NewBeneficiary} event
    /// @param beneficiary The beneficiary of the tokens
    /// @param totalAllocation The total amount of tokens allocated to `beneficiary`
    /// @param start The start timestamp
    /// @param cliffDuration The duration of the cliff period (can be 0)
    /// @param duration The duration of the vesting period (starting from `start`)
    function vestTokens(
        address beneficiary,
        uint256 totalAllocation,
        uint256 start,
        uint256 cliffDuration,
        uint256 duration
    ) public virtual onlyRole(VESTING_CONTROLLER_ROLE) {
        require(beneficiary != address(0), "Invalid beneficiary");
        require(
            vestingSchedules[beneficiary].totalAllocation == 0,
            "Beneficiary already exists"
        );
        require(totalAllocation > 0, "Invalid allocation");
        require(start > block.timestamp, "Invalid start");
        require(duration > 0, "Invalid duration");
        require(duration > cliffDuration, "Invalid cliff");

        vestingSchedules[beneficiary] = VestingSchedule({
            totalAllocation: totalAllocation,
            start: start,
            cliffDuration: cliffDuration,
            duration: duration,
            released: 0
        });

        token.safeTransferFrom(msg.sender, address(this), totalAllocation);

        emit NewBeneficiary(beneficiary, totalAllocation, start, cliffDuration, duration);
    }

    /// @notice Allows members of `DEFAULT_ADMIN_ROLE` to revoke tokens
    /// @dev All the unreleased tokens are sent to `msg.sender`
    /// Emits a {Revoked} event
    /// @param account The account to revoke tokens from
    function revoke(address account) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        VestingSchedule memory schedule = vestingSchedules[account];
        require(schedule.totalAllocation > 0, "Beneficiary doesn't exist");

        uint256 remainingAmount = schedule.totalAllocation - schedule.released;
        require(remainingAmount > 0, "All tokens unlocked");

        delete vestingSchedules[account];

        token.safeTransfer(msg.sender, remainingAmount);

        emit Revoked(account, remainingAmount);
    }

    /// @notice Releases tokens that have already vested
    /// @dev Emits a {Released} event
    function release() public virtual {
        uint256 releasable = releasableAmount(msg.sender);
        require(releasable > 0, "No releasable tokens");

        vestingSchedules[msg.sender].released += releasable;
        token.safeTransfer(msg.sender, releasable);

        emit Released(msg.sender, releasable);
    }

    /// @notice Calculates the amount of locked tokens for `account`
    /// @param account The address to check
    /// @return The amount of locked tokens for `account`
    function lockedAmount(address account) external view returns (uint256) {
        return
            vestingSchedules[account].totalAllocation - vestedAmount(account);
    }

    /// @notice Calculates the amount of releasable tokens for `account`
    /// @param account The address to check
    /// @return The amount of releasable tokens for `account`
    function releasableAmount(address account)
        public
        view
        virtual
        returns (uint256)
    {
        return vestedAmount(account) - vestingSchedules[account].released;
    }

    
    /// @notice Calculates the amount of tokens that has already vested for `account`. Uses a linear vesting curve
    /// @param account The address to check
    /// @return The amount of tokens that has already vested for `account`
    function vestedAmount(address account)
        public
        view
        virtual
        returns (uint256)
    {
        return _vestingSchedule(vestingSchedules[account], block.timestamp);
    }

    /// @dev Implementation of the vesting formula. This returns the amout vested, as a function of time, for
    /// an asset given its total historical allocation.
    /// @param schedule The vesting schedule to use in the calculation
    /// @param timestamp The timestamp to use in the calculation
    function _vestingSchedule(
        VestingSchedule memory schedule,
        uint256 timestamp
    ) internal view virtual returns (uint256) {
        if (schedule.duration == 0 || timestamp < schedule.start + schedule.cliffDuration) {
            return 0;
        } else if (timestamp > schedule.start + schedule.duration) {
            return schedule.totalAllocation;
        } else {
            return
                (schedule.totalAllocation * (timestamp - schedule.start)) /
                schedule.duration;
        }
    }
}