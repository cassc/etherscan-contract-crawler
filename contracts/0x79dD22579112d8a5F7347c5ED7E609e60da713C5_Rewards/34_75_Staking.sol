// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "../interfaces/IStaking.sol";
import "../interfaces/IManager.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import {SafeMathUpgradeable as SafeMath} from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import {MathUpgradeable as Math} from "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import {OwnableUpgradeable as Ownable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {EnumerableSetUpgradeable as EnumerableSet} from "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";
import {PausableUpgradeable as Pausable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

contract Staking is IStaking, Initializable, Ownable, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    IERC20 public tokeToken;
    IManager public manager;

    address public treasury;

    uint256 public withheldLiquidity;
    //userAddress -> withdrawalInfo
    mapping(address => WithdrawalInfo) public requestedWithdrawals;

    //userAddress -> -> scheduleIndex -> staking detail
    mapping(address => mapping(uint256 => StakingDetails)) public userStakings;

    //userAddress -> scheduleIdx[]
    mapping(address => uint256[]) public userStakingSchedules;

    //Schedule id/index counter
    uint256 public nextScheduleIndex;
    //scheduleIndex/id -> schedule
    mapping(uint256 => StakingSchedule) public schedules;
    //scheduleIndex/id[]
    EnumerableSet.UintSet private scheduleIdxs;

    //Can deposit into a non-public schedule
    mapping(address => bool) public override permissionedDepositors;

    modifier onlyPermissionedDepositors() {
        require(_isAllowedPermissionedDeposit(), "CALLER_NOT_PERMISSIONED");
        _;
    }

    function initialize(
        IERC20 _tokeToken,
        IManager _manager,
        address _treasury
    ) public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();

        require(address(_tokeToken) != address(0), "INVALID_TOKETOKEN");
        require(address(_manager) != address(0), "INVALID_MANAGER");
        require(_treasury != address(0), "INVALID_TREASURY");

        tokeToken = _tokeToken;
        manager = _manager;
        treasury = _treasury;

        //We want to be sure the schedule used for LP staking is first
        //because the order in which withdraws happen need to start with LP stakes
        _addSchedule(
            StakingSchedule({
                cliff: 0,
                duration: 1,
                interval: 1,
                setup: true,
                isActive: true,
                hardStart: 0,
                isPublic: true
            })
        );
    }

    function addSchedule(StakingSchedule memory schedule) external override onlyOwner {
        _addSchedule(schedule);
    }

    function setPermissionedDepositor(address account, bool canDeposit)
        external
        override
        onlyOwner
    {
        permissionedDepositors[account] = canDeposit;
    }

    function setUserSchedules(address account, uint256[] calldata userSchedulesIdxs)
        external
        override
        onlyOwner
    {
        userStakingSchedules[account] = userSchedulesIdxs;
    }

    function getSchedules()
        external
        view
        override
        returns (StakingScheduleInfo[] memory retSchedules)
    {
        uint256 length = scheduleIdxs.length();
        retSchedules = new StakingScheduleInfo[](length);
        for (uint256 i = 0; i < length; i++) {
            retSchedules[i] = StakingScheduleInfo(
                schedules[scheduleIdxs.at(i)],
                scheduleIdxs.at(i)
            );
        }
    }

    function removeSchedule(uint256 scheduleIndex) external override onlyOwner {
        require(scheduleIdxs.contains(scheduleIndex), "INVALID_SCHEDULE");

        scheduleIdxs.remove(scheduleIndex);
        delete schedules[scheduleIndex];

        emit ScheduleRemoved(scheduleIndex);
    }

    function getStakes(address account)
        external
        view
        override
        returns (StakingDetails[] memory stakes)
    {
        stakes = _getStakes(account);
    }

    function balanceOf(address account) external view override returns (uint256 value) {
        value = 0;
        uint256 scheduleCount = userStakingSchedules[account].length;
        for (uint256 i = 0; i < scheduleCount; i++) {
            uint256 remaining = userStakings[account][userStakingSchedules[account][i]].initial.sub(
                userStakings[account][userStakingSchedules[account][i]].withdrawn
            );
            uint256 slashed = userStakings[account][userStakingSchedules[account][i]].slashed;
            if (remaining > slashed) {
                value = value.add(remaining.sub(slashed));
            }
        }
    }

    function availableForWithdrawal(address account, uint256 scheduleIndex)
        external
        view
        override
        returns (uint256)
    {
        return _availableForWithdrawal(account, scheduleIndex);
    }

    function unvested(address account, uint256 scheduleIndex)
        external
        view
        override
        returns (uint256 value)
    {
        value = 0;
        StakingDetails memory stake = userStakings[account][scheduleIndex];

        value = stake.initial.sub(_vested(account, scheduleIndex));
    }

    function vested(address account, uint256 scheduleIndex)
        external
        view
        override
        returns (uint256 value)
    {
        return _vested(account, scheduleIndex);
    }

    function deposit(uint256 amount, uint256 scheduleIndex) external override {
        _depositFor(msg.sender, amount, scheduleIndex);
    }

    function depositFor(
        address account,
        uint256 amount,
        uint256 scheduleIndex
    ) external override {
        _depositFor(account, amount, scheduleIndex);
    }

    function depositWithSchedule(
        address account,
        uint256 amount,
        StakingSchedule calldata schedule
    ) external override onlyPermissionedDepositors {
        uint256 scheduleIx = nextScheduleIndex;
        _addSchedule(schedule);
        _depositFor(account, amount, scheduleIx);
    }

    function requestWithdrawal(uint256 amount) external override {
        require(amount > 0, "INVALID_AMOUNT");
        StakingDetails[] memory stakes = _getStakes(msg.sender);
        uint256 length = stakes.length;
        uint256 stakedAvailable = 0;
        for (uint256 i = 0; i < length; i++) {
            stakedAvailable = stakedAvailable.add(
                _availableForWithdrawal(msg.sender, stakes[i].scheduleIx)
            );
        }

        require(stakedAvailable >= amount, "INSUFFICIENT_AVAILABLE");

        withheldLiquidity = withheldLiquidity.sub(requestedWithdrawals[msg.sender].amount).add(
            amount
        );
        requestedWithdrawals[msg.sender].amount = amount;
        if (manager.getRolloverStatus()) {
            requestedWithdrawals[msg.sender].minCycleIndex = manager.getCurrentCycleIndex().add(2);
        } else {
            requestedWithdrawals[msg.sender].minCycleIndex = manager.getCurrentCycleIndex().add(1);
        }

        emit WithdrawalRequested(msg.sender, amount);
    }

    function withdraw(uint256 amount) external override {
        require(amount <= requestedWithdrawals[msg.sender].amount, "WITHDRAW_INSUFFICIENT_BALANCE");

        require(amount > 0, "NO_WITHDRAWAL");

        require(
            requestedWithdrawals[msg.sender].minCycleIndex <= manager.getCurrentCycleIndex(),
            "INVALID_CYCLE"
        );

        StakingDetails[] memory stakes = _getStakes(msg.sender);
        uint256 available = 0;
        uint256 length = stakes.length;
        uint256 remainingAmount = amount;
        uint256 stakedAvailable = 0;
        for (uint256 i = 0; i < length && remainingAmount > 0; i++) {
            stakedAvailable = _availableForWithdrawal(msg.sender, stakes[i].scheduleIx);
            available = available.add(stakedAvailable);
            if (stakedAvailable < remainingAmount) {
                remainingAmount = remainingAmount.sub(stakedAvailable);
                stakes[i].withdrawn = stakes[i].withdrawn.add(stakedAvailable);
            } else {
                stakes[i].withdrawn = stakes[i].withdrawn.add(remainingAmount);
                remainingAmount = 0;
            }
            userStakings[msg.sender][stakes[i].scheduleIx] = stakes[i];
        }

        require(remainingAmount == 0, "INSUFFICIENT_AVAILABLE"); //May not need to check this again

        requestedWithdrawals[msg.sender].amount = requestedWithdrawals[msg.sender].amount.sub(
            amount
        );

        if (requestedWithdrawals[msg.sender].amount == 0) {
            delete requestedWithdrawals[msg.sender];
        }

        withheldLiquidity = withheldLiquidity.sub(amount);
        tokeToken.safeTransfer(msg.sender, amount);

        emit WithdrawCompleted(msg.sender, amount);
    }

    function slash(
        address account,
        uint256 amount,
        uint256 scheduleIndex
    ) external onlyOwner {
        StakingSchedule storage schedule = schedules[scheduleIndex];
        require(amount > 0, "INVALID_AMOUNT");
        require(schedule.setup, "INVALID_SCHEDULE");

        StakingDetails memory userStake = userStakings[account][scheduleIndex];
        require(userStake.initial > 0, "NO_VESTING");

        uint256 availableToSlash = 0;
        uint256 remaining = userStake.initial.sub(userStake.withdrawn);
        if (remaining > userStake.slashed) {
            availableToSlash = remaining.sub(userStake.slashed);
        }

        require(availableToSlash >= amount, "INSUFFICIENT_AVAILABLE");

        userStake.slashed = userStake.slashed.add(amount);
        userStakings[account][scheduleIndex] = userStake;

        tokeToken.safeTransfer(treasury, amount);

        emit Slashed(account, amount, scheduleIndex);
    }

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function _availableForWithdrawal(address account, uint256 scheduleIndex)
        private
        view
        returns (uint256)
    {
        StakingDetails memory stake = userStakings[account][scheduleIndex];
        uint256 vestedWoWithdrawn = _vested(account, scheduleIndex).sub(stake.withdrawn);
        if (stake.slashed > vestedWoWithdrawn) return 0;

        return vestedWoWithdrawn.sub(stake.slashed);
    }

    function _depositFor(
        address account,
        uint256 amount,
        uint256 scheduleIndex
    ) private {
        StakingSchedule memory schedule = schedules[scheduleIndex];
        require(!paused(), "Pausable: paused");
        require(amount > 0, "INVALID_AMOUNT");
        require(schedule.setup, "INVALID_SCHEDULE");
        require(schedule.isActive, "INACTIVE_SCHEDULE");
        require(account != address(0), "INVALID_ADDRESS");
        require(schedule.isPublic || _isAllowedPermissionedDeposit(), "PERMISSIONED_SCHEDULE");

        StakingDetails memory userStake = userStakings[account][scheduleIndex];
        if (userStake.initial == 0) {
            userStakingSchedules[account].push(scheduleIndex);
        }
        userStake.initial = userStake.initial.add(amount);
        if (schedule.hardStart > 0) {
            userStake.started = schedule.hardStart;
        } else {
            // solhint-disable-next-line not-rely-on-time
            userStake.started = block.timestamp;
        }
        userStake.scheduleIx = scheduleIndex;
        userStakings[account][scheduleIndex] = userStake;

        tokeToken.safeTransferFrom(msg.sender, address(this), amount);

        emit Deposited(account, amount, scheduleIndex);
    }

    function _vested(address account, uint256 scheduleIndex) private view returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        uint256 timestamp = block.timestamp;
        uint256 value = 0;
        StakingDetails memory stake = userStakings[account][scheduleIndex];
        StakingSchedule memory schedule = schedules[scheduleIndex];

        uint256 cliffTimestamp = stake.started.add(schedule.cliff);
        if (cliffTimestamp <= timestamp) {
            if (cliffTimestamp.add(schedule.duration) <= timestamp) {
                value = stake.initial;
            } else {
                uint256 secondsStaked = Math.max(timestamp.sub(cliffTimestamp), 1);
                uint256 effectiveSecondsStaked = (secondsStaked.mul(schedule.interval)).div(
                    schedule.interval
                );
                value = stake.initial.mul(effectiveSecondsStaked).div(schedule.duration);
            }
        }

        return value;
    }

    function _addSchedule(StakingSchedule memory schedule) private {
        require(schedule.duration > 0, "INVALID_DURATION");
        require(schedule.interval > 0, "INVALID_INTERVAL");

        schedule.setup = true;
        uint256 index = nextScheduleIndex;
        schedules[index] = schedule;
        scheduleIdxs.add(index);
        nextScheduleIndex = nextScheduleIndex.add(1);

        emit ScheduleAdded(
            index,
            schedule.cliff,
            schedule.duration,
            schedule.interval,
            schedule.setup,
            schedule.isActive,
            schedule.hardStart
        );
    }

    function _getStakes(address account) private view returns (StakingDetails[] memory stakes) {
        uint256 stakeCnt = userStakingSchedules[account].length;
        stakes = new StakingDetails[](stakeCnt);

        for (uint256 i = 0; i < stakeCnt; i++) {
            stakes[i] = userStakings[account][userStakingSchedules[account][i]];
        }
    }

    function _isAllowedPermissionedDeposit() private view returns (bool) {
        return permissionedDepositors[msg.sender] || msg.sender == owner();
    }
}