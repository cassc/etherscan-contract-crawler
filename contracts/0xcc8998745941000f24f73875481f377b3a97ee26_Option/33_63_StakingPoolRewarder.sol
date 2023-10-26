// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../interfaces/IStakingPoolRewarder.sol";
import "../libraries/TransferHelper.sol";

/**
 * @title StakingPoolRewarder
 * @author DeOrderBook
 * @custom:license Copyright (c) DeOrderBook, 2023 — All Rights Reserved
 * @notice An upgradeable contract for releasing rewards based on a vesting schedule.
 * @dev Utilizes OpenZeppelin's upgradeable contracts for basic contract controls and math operations.
 *      It uses a reentrancy block to prevent reentrancy attacks.
 */
contract StakingPoolRewarder is OwnableUpgradeable, IStakingPoolRewarder {
    using SafeMathUpgradeable for uint256;

    /**
     * @notice Emitted when a new vesting schedule is added for a user
     * @dev The event signals the addition of a new vesting schedule, providing the address of the user, amount to be vested, start time, end time, and vesting step
     * @param user The address of the user
     * @param amount The total amount that will be vested
     * @param startTime The start time of the vesting period
     * @param endTime The end time of the vesting period
     * @param step The interval at which vestable amounts are accumulated
     */
    event VestingScheduleAdded(address indexed user, uint256 amount, uint256 startTime, uint256 endTime, uint256 step);

    /**
     * @notice Emitted when the vesting settings are changed
     * @dev The event signals the change in vesting settings, providing the new percentage allocated to vesting, new claim duration, and new claim step
     * @param percentageToVestingSchedule The new percentage of rewards that will be locked in the vesting schedule
     * @param claimDuration The new duration of claims
     * @param claimStep The new interval at which claims can be made
     */
    event VestingSettingChanged(uint8 percentageToVestingSchedule, uint256 claimDuration, uint256 claimStep);

    /**
     * @notice Emitted when tokens are vested by a user from a pool
     * @dev The event signals the vesting of tokens, providing the user address, the pool id, and the amount vested
     * @param user The address of the user
     * @param poolId The id of the pool from which the tokens were vested
     * @param amount The amount of tokens vested
     */
    event TokenVested(address indexed user, uint256 poolId, uint256 amount);

    /**
     * @notice Struct to represent a vesting schedule for a user
     * @dev Defines a vesting schedule with the amount to be vested, start and end times, vesting step, and the last claim time
     * @param amount Total amount to be vested over the complete period
     * @param startTime Unix timestamp in seconds for the period start time
     * @param endTime Unix timestamp in seconds for the period end time
     * @param step Interval in seconds at which vestable amounts are accumulated
     * @param lastClaimTime Unix timestamp in seconds for the last claim time
     */
    struct VestingSchedule {
        uint128 amount;
        uint32 startTime;
        uint32 endTime;
        uint32 step;
        uint32 lastClaimTime;
    }

    /**
     * @notice Mapping of vesting schedules for each user per staking pool
     * @dev Maps each user address to a mapping of pool ids to vesting schedules
     */
    mapping(address => mapping(uint256 => VestingSchedule)) public vestingSchedules;

    /**
     * @notice Mapping of claimable amounts for each user per staking pool
     * @dev Maps each user address to a mapping of pool ids to claimable amounts
     */
    mapping(address => mapping(uint256 => uint256)) public claimableAmounts;

    /**
     * @notice The address of the staking pools
     * @dev The staking pool contract's address
     */
    address public stakingPools;

    /**
     * @notice The token to be used as rewards
     * @dev The contract address of the ERC20 token to be used as rewards
     */
    address public rewardToken;

    /**
     * @notice The dispatcher of the rewards
     * @dev The contract address of the reward dispatcher
     */
    address public rewardDispatcher;

    /**
     * @notice The percentage of the rewards to be locked in the vesting schedule
     * @dev The proportion (out of 100) of rewards that will be vested over time
     */
    uint8 public percentageToVestingSchedule;

    /**
     * @notice The duration of the claims in seconds
     * @dev The total duration of the vesting period
     */
    uint256 public claimDuration;

    /**
     * @notice The interval at which the claims can be made
     * @dev The step (in seconds) at which the user can claim vested tokens
     */
    uint256 public claimStep;

    /**
     * @notice Flag to block reentrancy
     * @dev Used as a guard to prevent reentrancy attacks
     */
    bool private locked;

    /**
     * @notice Modifier to block reentrancy attacks
     * @dev Requires that the contract is not currently executing a state-changing external function call
     */
    modifier blockReentrancy() {
        require(!locked, "Reentrancy is blocked");
        locked = true;
        _;
        locked = false;
    }

    /**
     * @notice Initializes the StakingPoolRewarder contract
     * @dev Initializes the contract with the given parameters. Requires that the addresses are not zero addresses.
     * @param _stakingPools The address of the staking pools
     * @param _rewardToken The token to be used as rewards
     * @param _rewardDispatcher The dispatcher of the rewards
     * @param _percentageToVestingSchedule The percentage of the rewards to be locked in the vesting schedule
     * @param _claimDuration The duration of the claims in seconds
     * @param _claimStep The interval at which the claims can be made
     */
    function __StakingPoolRewarder_init(
        address _stakingPools,
        address _rewardToken,
        address _rewardDispatcher,
        uint8 _percentageToVestingSchedule,
        uint256 _claimDuration,
        uint256 _claimStep
    ) public initializer {
        __Ownable_init();
        require(_stakingPools != address(0), "StakingPoolRewarder: stakingPools zero address");
        require(_rewardToken != address(0), "StakingPoolRewarder: rewardToken zero address");
        require(_rewardDispatcher != address(0), "StakingPoolRewarder: rewardDispatcher zero address");

        stakingPools = _stakingPools;
        rewardToken = _rewardToken;
        rewardDispatcher = _rewardDispatcher;

        percentageToVestingSchedule = _percentageToVestingSchedule;
        claimDuration = _claimDuration;
        claimStep = _claimStep;
    }

    /**
     * @notice Modifier to allow only the staking pools to execute a function
     * @dev Requires that the caller is the staking pools
     */
    modifier onlyStakingPools() {
        require(msg.sender == stakingPools, "StakingPoolRewarder: only StakingPools allowed to call");
        _;
    }

    /**
     * @notice Updates the vesting setting
     * @dev Allows the owner to change the percentage of the rewards that go to the vesting schedule and the duration and interval of the claims. Emits the VestingSettingChanged event.
     * @param _percentageToVestingSchedule The new percentage of the rewards to be locked in the vesting schedule
     * @param _claimDuration The new duration of the claims in seconds
     * @param _claimStep The new interval at which the claims can be made
     */
    function updateVestingSetting(
        uint8 _percentageToVestingSchedule,
        uint256 _claimDuration,
        uint256 _claimStep
    ) external onlyOwner {
        percentageToVestingSchedule = _percentageToVestingSchedule;
        claimDuration = _claimDuration;
        claimStep = _claimStep;

        emit VestingSettingChanged(_percentageToVestingSchedule, _claimDuration, _claimStep);
    }

    /**
     * @notice Sets the reward dispatcher
     * @dev Allows the owner to change the address of the reward dispatcher. Requires that the new address is not a zero address.
     * @param _rewardDispatcher The new address of the reward dispatcher
     */
    function setRewardDispatcher(address _rewardDispatcher) external onlyOwner {
        require(_rewardDispatcher != address(0), "StakingPoolRewarder: rewardDispatcher zero address");
        rewardDispatcher = _rewardDispatcher;
    }

    /**
     * @notice Update the vesting schedule for a user.
     * @dev Updates the vesting schedule for a given user with new parameters. Emits a VestingScheduleAdded event.
     * @param user Address of the user.
     * @param poolId The id of the staking pool.
     * @param amount Total amount to be vested over the period.
     * @param startTime Unix timestamp in seconds for the period start time.
     * @param endTime Unix timestamp in seconds for the period end time.
     * @param step Interval in seconds at which vestable amounts are accumulated.
     */
    function updateVestingSchedule(
        address user,
        uint256 poolId,
        uint256 amount,
        uint256 startTime,
        uint256 endTime,
        uint256 step
    ) private {
        require(user != address(0), "StakingPoolRewarder: zero address");
        require(amount > 0, "StakingPoolRewarder: zero amount");
        require(startTime < endTime, "StakingPoolRewarder: invalid time range");
        require(step > 0 && endTime.sub(startTime) % step == 0, "StakingPoolRewarder: invalid step");

        // Overflow checks
        require(uint256(uint128(amount)) == amount, "StakingPoolRewarder: amount overflow");
        require(uint256(uint32(startTime)) == startTime, "StakingPoolRewarder: startTime overflow");
        require(uint256(uint32(endTime)) == endTime, "StakingPoolRewarder: endTime overflow");
        require(uint256(uint32(step)) == step, "StakingPoolRewarder: step overflow");

        vestingSchedules[user][poolId] = VestingSchedule({
            amount: uint128(amount),
            startTime: uint32(startTime),
            endTime: uint32(endTime),
            step: uint32(step),
            lastClaimTime: uint32(startTime)
        });

        emit VestingScheduleAdded(user, amount, startTime, endTime, step);
    }

    /**
     * @notice Calculates the total reward for a user.
     * @dev It calculates the total amount of reward that a user could claim at this moment. It includes withdrawableFromVesting, unvestedAmount, and claimableAmount. Overrides the function in the parent contract.
     * @param user Address of the user.
     * @param poolId The id of the staking pool.
     * @return total The total reward amount that user could claim at this moment.
     */
    function calculateTotalReward(address user, uint256 poolId) external view override returns (uint256 total) {
        (uint256 withdrawableFromVesting, , ) = _calculateWithdrawableFromVesting(user, poolId, block.timestamp);
        uint256 claimableAmount = claimableAmounts[user][poolId];
        uint256 unvestedAmount = _calculateUnvestedAmountAtCurrentStep(user, poolId, block.timestamp);
        return withdrawableFromVesting.add(unvestedAmount).add(claimableAmount);
    }

    /**
     * @notice Calculates the withdrawable reward for a user.
     * @dev It calculates the total amount of reward that a user could withdraw at this moment. It includes withdrawableFromVesting and claimableAmount. Overrides the function in the parent contract.
     * @param user Address of the user.
     * @param poolId The id of the staking pool.
     * @return total The total reward amount that user could withdraw at this moment.
     */
    function calculateWithdrawableReward(address user, uint256 poolId) external view override returns (uint256 total) {
        (uint256 withdrawableFromVesting, , ) = _calculateWithdrawableFromVesting(user, poolId, block.timestamp);
        uint256 claimableAmount = claimableAmounts[user][poolId];
        return withdrawableFromVesting.add(claimableAmount);
    }

    /**
     * @notice Calculates the amount withdrawable from vesting for a user.
     * @dev Returns the amount that can be withdrawn from the vesting schedule for a given user at the current block timestamp.
     * @param user Address of the user.
     * @param poolId The id of the staking pool.
     * @return amount The amount withdrawable from vesting at this moment.
     */
    function calculateWithdrawableFromVesting(address user, uint256 poolId) external view returns (uint256 amount) {
        (uint256 withdrawable, , ) = _calculateWithdrawableFromVesting(user, poolId, block.timestamp);
        return withdrawable;
    }

    /**
     * @notice Calculates the amount withdrawable from vesting for a user.
     * @dev Calculates the amount that can be withdrawn from the vesting schedule for a given user, the new claim time, and whether all amounts have been vested. If the amount or vesting schedule is zero, or the timestamp is before the start time or the current step time is before or equal to the last claim time, it returns zero. If all amounts have been vested, it returns the total amount to vest minus the amount already vested. If it's partially vested, it returns the amount to vest for the steps to vest.
     * @param user Address of the user.
     * @param poolId The id of the staking pool.
     * @param timestamp Current timestamp.
     * @return amount The amount withdrawable from vesting at this moment.
     * @return newClaimTime The new claim time.
     * @return allVested Whether all amounts have been vested.
     */
    function _calculateWithdrawableFromVesting(
        address user,
        uint256 poolId,
        uint256 timestamp
    )
        private
        view
        returns (
            uint256 amount,
            uint256 newClaimTime,
            bool allVested
        )
    {
        VestingSchedule memory vestingSchedule = vestingSchedules[user][poolId];
        if (vestingSchedule.amount == 0) return (0, 0, false);
        if (timestamp <= uint256(vestingSchedule.startTime)) return (0, 0, false);

        uint256 currentStepTime = MathUpgradeable.min(
            timestamp
            .sub(uint256(vestingSchedule.startTime))
            .div(uint256(vestingSchedule.step))
            .mul(uint256(vestingSchedule.step))
            .add(uint256(vestingSchedule.startTime)),
            uint256(vestingSchedule.endTime)
        );

        if (currentStepTime <= uint256(vestingSchedule.lastClaimTime)) return (0, 0, false);

        uint256 totalSteps = uint256(vestingSchedule.endTime).sub(uint256(vestingSchedule.startTime)).div(
            vestingSchedule.step
        );

        if (currentStepTime == uint256(vestingSchedule.endTime)) {
            // All vested
            uint256 stepsVested = uint256(vestingSchedule.lastClaimTime).sub(uint256(vestingSchedule.startTime)).div(
                vestingSchedule.step
            );
            uint256 amountToVest = uint256(vestingSchedule.amount).sub(
                uint256(vestingSchedule.amount).div(totalSteps).mul(stepsVested)
            );
            return (amountToVest, currentStepTime, true);
        } else {
            // Partially vested
            uint256 stepsToVest = currentStepTime.sub(uint256(vestingSchedule.lastClaimTime)).div(vestingSchedule.step);
            uint256 amountToVest = uint256(vestingSchedule.amount).div(totalSteps).mul(stepsToVest);
            return (amountToVest, currentStepTime, false);
        }
    }

    /**
     * @notice Calculate the amount of tokens that haven't vested at the current step for a specific user and pool.
     * @dev This function uses the timestamp to identify the current step and returns the unvested amount of tokens.
     * @param user The address of the user.
     * @param poolId The id of the pool.
     * @param timestamp The current timestamp.
     * @return The unvested amount.
     */
    function _calculateUnvestedAmountAtCurrentStep(
        address user,
        uint256 poolId,
        uint256 timestamp
    ) private view returns (uint256) {
        if (timestamp < uint256(vestingSchedules[user][poolId].startTime) || vestingSchedules[user][poolId].amount == 0)
            return 0;
        uint256 currentStepTime = MathUpgradeable.min(
            timestamp
            .sub(uint256(vestingSchedules[user][poolId].startTime))
            .div(uint256(vestingSchedules[user][poolId].step))
            .mul(uint256(vestingSchedules[user][poolId].step))
            .add(uint256(vestingSchedules[user][poolId].startTime)),
            uint256(vestingSchedules[user][poolId].endTime)
        );
        return _calculateUnvestedAmount(user, poolId, currentStepTime);
    }

    /**
     * @notice Calculate the amount of tokens that haven't vested at a given step time for a specific user and pool.
     * @dev This function uses the stepTime to identify the current step and returns the unvested amount of tokens.
     * @param user The address of the user.
     * @param poolId The id of the pool.
     * @param stepTime The step time.
     * @return The unvested amount.
     */
    function _calculateUnvestedAmount(
        address user,
        uint256 poolId,
        uint256 stepTime
    ) private view returns (uint256) {
        if (vestingSchedules[user][poolId].amount == 0) return 0;

        uint256 totalSteps = uint256(vestingSchedules[user][poolId].endTime)
        .sub(uint256(vestingSchedules[user][poolId].startTime))
        .div(vestingSchedules[user][poolId].step);
        uint256 stepsVested = stepTime.sub(uint256(vestingSchedules[user][poolId].startTime)).div(
            vestingSchedules[user][poolId].step
        );
        return
            uint256(vestingSchedules[user][poolId].amount).sub(
                uint256(vestingSchedules[user][poolId].amount).div(totalSteps).mul(stepsVested)
            );
    }

    /**
     * @notice Internal function to withdraw vested tokens for a specific user and pool at a given timestamp.
     * @dev This function calculates the amount that can be withdrawn, updates the vesting schedule if necessary, and returns the withdrawn amount.
     * @param user The address of the user.
     * @param poolId The id of the pool.
     * @param timestamp The timestamp at which to perform the withdrawal.
     * @return The amount of tokens withdrawn.
     */
    function _withdrawFromVesting(
        address user,
        uint256 poolId,
        uint256 timestamp
    ) private returns (uint256) {
        (uint256 lastVestedAmount, uint256 newClaimTime, bool allVested) = _calculateWithdrawableFromVesting(
            user,
            poolId,
            timestamp
        );
        if (lastVestedAmount > 0) {
            if (allVested) {
                delete vestingSchedules[user][poolId];
            } else {
                vestingSchedules[user][poolId].lastClaimTime = uint32(newClaimTime);
            }
        }
        return lastVestedAmount;
    }

    /**
     * @notice Handles the reward event for a specific user and pool.
     * @dev This function is called when a user earns rewards from staking in a pool. It simply calls the internal _onReward function.
     * @param poolId The id of the pool.
     * @param user The address of the user.
     * @param amount The amount of tokens rewarded.
     * @param entryTime The timestamp at which the reward was earned.
     */
    function onReward(
        uint256 poolId,
        address user,
        uint256 amount,
        uint256 entryTime
    ) external override onlyStakingPools {
        _onReward(poolId, user, amount, entryTime);
    }

    /**
     * @notice Internal function that handles the reward event for a specific user and pool.
     * @dev This function calculates the vested and unvested amounts of the reward, updates the vesting schedule and claimable amounts, and emits a TokenVested event.
     * @param poolId The id of the pool.
     * @param user The address of the user.
     * @param amount The amount of tokens rewarded.
     * @param entryTime The timestamp at which the reward was earned.
     */
    function _onReward(
        uint256 poolId,
        address user,
        uint256 amount,
        uint256 entryTime
    ) private blockReentrancy {
        require(user != address(0), "StakingPoolRewarder: zero address");

        uint256 lastVestedAmount = _withdrawFromVesting(user, poolId, entryTime);

        uint256 newUnvestedAmount = 0;
        uint256 newVestedAmount = 0;
        if (amount > 0) {
            newUnvestedAmount = amount.mul(uint256(percentageToVestingSchedule)).div(100);
            newVestedAmount = amount.sub(newUnvestedAmount);
        }

        if (newUnvestedAmount > 0) {
            uint256 lastUnvestedAmount = _calculateUnvestedAmountAtCurrentStep(user, poolId, entryTime);
            updateVestingSchedule(
                user,
                poolId,
                newUnvestedAmount.add(lastUnvestedAmount),
                entryTime,
                entryTime.add(claimDuration),
                claimStep
            );
        }

        uint256 newEntryVestedAmount = _withdrawFromVesting(user, poolId, block.timestamp);
        uint256 totalVested = lastVestedAmount.add(newVestedAmount).add(newEntryVestedAmount);
        claimableAmounts[user][poolId] = claimableAmounts[user][poolId].add(totalVested);
        emit TokenVested(user, poolId, totalVested);
    }

    /**
     * @notice Allows a user to claim vested rewards from a specific pool.
     * @dev This function checks if there are claimable rewards, transfers the rewards to the user, and returns the claimed amount.
     * @param poolId The id of the pool.
     * @param user The address of the user.
     * @return The amount of tokens claimed.
     */
    function claimVestedReward(uint256 poolId, address user)
        external
        override
        onlyStakingPools
        blockReentrancy
        returns (uint256)
    {
        require(poolId > 0, "StakingPoolRewarder: poolId is 0");
        uint256 claimableAmount = claimableAmounts[user][poolId];
        claimableAmounts[user][poolId] = 0;
        if (claimableAmount > 0) {
            TransferHelper.safeTransferFrom(rewardToken, rewardDispatcher, user, claimableAmount);
        }

        return claimableAmount;
    }
}