// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IMnt.sol";
import "./interfaces/IVesting.sol";
import "./libraries/PauseControl.sol";
import "./libraries/ErrorCodes.sol";

/**
 * @title Vesting contract provides unlocking of tokens on a schedule. It uses the *graded vesting* way,
 * which unlocks a specific amount of balance every period of time, until all balance unlocked.
 *
 * Vesting Schedule.
 *
 * The schedule of a vesting is described by data structure `VestingSchedule`: starting from the start timestamp
 * throughout the duration, the entire amount of totalAmount tokens will be unlocked.
 *
 * Interface.
 *
 * - `withdraw` - withdraw released tokens.
 * - `createVestingSchedule` - allows admin to create a new vesting schedule for an account.
 * - `revokeVestingSchedule` - allows admin to revoke the vesting schedule. Tokens already vested
 * transfer to the account, the rest are returned to the vesting contract.
 */

contract Vesting is IVesting, AccessControl, PauseControl, Initializable {
    using SafeERC20Upgradeable for IMnt;

    /// @notice The right part is the keccak-256 hash of variable name
    bytes32 public constant GATEKEEPER = bytes32(0x20162831d2f54c3e11eebafebfeda495d4c52c67b1708251179ec91fb76dd3b2);
    /// @dev Value is the Keccak-256 hash of "TOKEN_PROVIDER"
    bytes32 public constant TOKEN_PROVIDER =
        bytes32(0x8c60700f65fcee73179f64477eb1484ea199744913cfa6e5fe87df1dcd47e13d);

    IMnt public mnt;
    IBuyback public buyback;

    mapping(address => VestingSchedule) public schedules;
    mapping(address => bool) public delayList;
    uint256 public allocation;
    uint256 public freeAllocation;

    /**
     * @notice Construct a vesting contract.
     * @param _admin The address of the Admin
     * @param _mnt The address of the MNT contract.
     */
    function initialize(
        address _admin,
        IMnt _mnt,
        IBuyback _buyback
    ) public initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(GATEKEEPER, _admin);
        _grantRole(TOKEN_PROVIDER, _admin);
        mnt = _mnt;
        buyback = _buyback;
    }

    /// @inheritdoc IVesting
    function withdraw(uint256 amount_) external checkPaused(WITHDRAW_OP) {
        require(!delayList[msg.sender], ErrorCodes.DELAY_LIST_LIMIT);

        VestingSchedule storage schedule = schedules[msg.sender];

        require(schedule.start != 0, ErrorCodes.NO_VESTING_SCHEDULES);

        uint256 unreleased = releasableAmount(msg.sender);
        if (amount_ == type(uint256).max) {
            amount_ = unreleased;
        }
        require(amount_ > 0, ErrorCodes.MNT_AMOUNT_IS_ZERO);
        require(amount_ <= unreleased, ErrorCodes.INSUFFICIENT_UNRELEASED_TOKENS);

        uint256 mntRemaining = mnt.balanceOf(address(this));
        require(amount_ <= mntRemaining, ErrorCodes.INSUFFICIENT_TOKEN_IN_VESTING_CONTRACT);

        allocation -= amount_;
        schedule.released = schedule.released + amount_;
        // Remove the vesting schedule if all tokens were released to the account.
        if (schedule.released == schedule.totalAmount) {
            delete schedules[msg.sender];
        }

        emit Withdrawn(msg.sender, amount_);

        buyback.updateBuybackAndVotingWeights(msg.sender);

        mnt.safeTransfer(msg.sender, amount_);
    }

    /// @inheritdoc IVesting
    function refill(uint256 amount) external onlyRole(TOKEN_PROVIDER) {
        require(amount > 0, ErrorCodes.MNT_AMOUNT_IS_ZERO);
        allocation += amount;
        freeAllocation += amount;
        mnt.safeTransferFrom(msg.sender, address(this), amount);
    }

    /// @inheritdoc IVesting
    function sweep(address recipient, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(amount > 0, ErrorCodes.MNT_AMOUNT_IS_ZERO);
        uint256 unallocated = mnt.balanceOf(address(this)) - allocation;
        if (amount == type(uint256).max) amount = unallocated;
        require(amount <= unallocated, ErrorCodes.INCORRECT_AMOUNT);
        mnt.safeTransfer(recipient, amount);
    }

    /// @inheritdoc IVesting
    function createVestingScheduleBatch(ScheduleData[] memory schedulesData) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 length = schedulesData.length;
        uint32 rightNow = uint32(getTime());
        uint256 _freeAllocation = freeAllocation;

        for (uint256 i = 0; i < length; i++) {
            ScheduleData memory schedule = schedulesData[i];

            require(schedule.target != address(0), ErrorCodes.TARGET_ADDRESS_CANNOT_BE_ZERO);
            require(schedules[schedule.target].start == 0, ErrorCodes.VESTING_SCHEDULE_ALREADY_EXISTS);
            require(schedule.totalAmount > 0, ErrorCodes.MNT_AMOUNT_IS_ZERO);
            require(_freeAllocation >= schedule.totalAmount, ErrorCodes.INSUFFICIENT_TOKENS_TO_CREATE_SCHEDULE);

            schedules[schedule.target] = VestingSchedule({
                totalAmount: schedule.totalAmount,
                released: 0,
                created: rightNow,
                start: rightNow + schedule.start,
                duration: schedule.duration,
                revocable: schedule.revocable
            });

            _freeAllocation -= schedule.totalAmount;

            emit VestingScheduleAdded(schedule.target, schedules[schedule.target]);
        }

        freeAllocation = _freeAllocation;
    }

    /// @inheritdoc IVesting
    function revokeVestingSchedule(address target_) external onlyRole(GATEKEEPER) {
        VestingSchedule storage schedule = schedules[target_];
        require(schedule.start != 0, ErrorCodes.NO_VESTING_SCHEDULE);
        require(schedule.revocable, ErrorCodes.SCHEDULE_IS_IRREVOCABLE);

        uint256 locked = lockedAmount(schedule, schedule.start);
        uint256 unreleased = releasableAmount(target_);
        uint256 mntRemaining = mnt.balanceOf(address(this));

        require(mntRemaining >= unreleased, ErrorCodes.INSUFFICIENT_TOKENS_FOR_RELEASE);

        allocation -= unreleased;
        freeAllocation += locked;
        delete schedules[target_];
        delete delayList[target_];

        emit VestingScheduleRevoked(target_, unreleased, locked);
        buyback.updateBuybackAndVotingWeights(target_);

        mnt.safeTransfer(target_, unreleased);
    }

    /// @inheritdoc IVesting
    function endOfVesting(address who_) external view returns (uint256) {
        VestingSchedule storage schedule = schedules[who_];
        return uint256(schedule.start) + uint256(schedule.duration);
    }

    /// @inheritdoc IVesting
    function lockedAmount(address who_) external view returns (uint256) {
        VestingSchedule storage schedule = schedules[who_];
        return lockedAmount(schedule, schedule.start);
    }

    /// @dev Gets locked amount of vesting schedule with custom start timestamp.
    ///      Used to calculate normal and "cliffless" amounts.
    function lockedAmount(VestingSchedule storage schedule, uint256 _start) internal view returns (uint256) {
        // lockedAmount = (end - time) * totalAmount / duration;
        // if the parameter `duration` is zero, it means that the allocated tokens are not locked for address `who`.

        uint256 _now = getTime();
        if (_now < _start) return schedule.totalAmount;

        uint256 _duration = uint256(schedule.duration);
        uint256 _end = _start + _duration;
        if (_duration == 0 || _now > _end) return 0;

        return ((_end - _now) * schedule.totalAmount) / _duration;
    }

    /// @inheritdoc IVesting
    function vestedAmount(address who_) public view returns (uint256) {
        VestingSchedule storage schedule = schedules[who_];
        return schedule.totalAmount - lockedAmount(schedule, schedule.start);
    }

    /// @inheritdoc IVesting
    function releasableAmount(address who_) public view returns (uint256) {
        return vestedAmount(who_) - schedules[who_].released;
    }

    /// @inheritdoc IVesting
    function getReleasableWithoutCliff(address account) external view returns (uint256) {
        VestingSchedule storage schedule = schedules[account];
        uint256 vested = schedule.totalAmount - lockedAmount(schedule, schedule.created);
        return vested - schedule.released;
    }

    /// @inheritdoc IVesting
    function addToDelayList(address who_) external onlyRole(GATEKEEPER) {
        require(schedules[who_].revocable, ErrorCodes.SHOULD_HAVE_REVOCABLE_SCHEDULE);
        emit AddedToDelayList(who_);
        delayList[who_] = true;
    }

    /// @inheritdoc IVesting
    function removeFromDelayList(address who_) external onlyRole(GATEKEEPER) {
        require(delayList[who_], ErrorCodes.MEMBER_NOT_IN_DELAY_LIST);
        emit RemovedFromDelayList(who_);
        delete delayList[who_];
    }

    // // // // Pause control // // // //

    bytes32 internal constant WITHDRAW_OP = "Withdraw";

    function validatePause(address) internal view override {
        require(hasRole(GATEKEEPER, msg.sender), ErrorCodes.UNAUTHORIZED);
    }

    function validateUnpause(address) internal view override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), ErrorCodes.UNAUTHORIZED);
    }

    // // // // Utils // // // //

    /// @dev Gets timestamp truncated to minutes
    function getTime() internal view virtual returns (uint256) {
        return block.timestamp / 1 minutes;
    }
}