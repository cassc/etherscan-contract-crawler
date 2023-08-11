//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {MSSCBase, CycleType} from "./base/MSSCBase.sol";
import {MembraneAuth} from "./lib/MembraneAuth.sol";
import {InstructionManagerLib as InstructionMgrLib} from "./lib/InstructionManagerLib.sol";
import {OnePeriodLockManagerLib as OnePeriodLockMgrLib} from "./lib/OnePeriodLockManagerLib.sol";
import {PeriodicLockManagerLib as PeriodicLockMgrLib} from "./lib/PeriodicLockManagerLib.sol";
import {ReentrancyGuard} from "@solmate/utils/ReentrancyGuard.sol";

contract MSSC is MSSCBase, MembraneAuth, ReentrancyGuard {
    using InstructionMgrLib for InstructionMgrLib.Instruction;
    using PeriodicLockMgrLib for PeriodicLockMgrLib.PeriodicLockInfo;
    using OnePeriodLockMgrLib for OnePeriodLockMgrLib.OnePeriodLockInfo;

    /*//////////////////////////////////////////////////////////////
                    EXTERNAL STATE-CHANGING METHODS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Register Settlement Cycle, this function can only be perfomed by a Membrane wallet.
     * @dev    Caller must transform obfuscatedId string to bytes32, pure strings are not supported.
     *
     * @param  cycleId Cycle's bytes32 obfuscatedId to register.
     * @param  instructions instructions to register.
     */
    function registerCycle(
        bytes32 cycleId,
        InstructionMgrLib.InstructionArgs[] calldata instructions
    ) external requiresAuth {
        _register(cycleId, instructions, CycleType.Unlocked);

        emit RegisterCycle(cycleId, instructions);
    }

    /**
     * @notice Register Settlement Cycle with infinite periodic locks,
     *             this function can only be perfomed by a Membrane wallet.
     * @dev    Caller must transform obfuscatedId string to bytes32, pure strings are not supported.
     *
     * @param  cycleId Cycle's bytes32 obfuscatedId to register.
     * @param  instructions instructions to register.
     * @param  hashlock hashlock to be set for the hybrid cycle, will be used for further checks.
     */
    function registerCycleWithPeriodicLocks(
        bytes32 cycleId,
        InstructionMgrLib.InstructionArgs[] calldata instructions,
        bytes32 hashlock
    ) external requiresAuth {
        _register(cycleId, instructions, CycleType.PeriodicLock);

        _periodicLocks[cycleId].storeHashlock(hashlock);
        _periodicLocks[cycleId].init(cycleId);

        emit RegisterCycleWithPeriodicLocks(cycleId, instructions, hashlock);
    }

    /**
     * @notice Register Settlement Cycle with a single lock, this function can only be perfomed by a Membrane wallet.
     * @dev    Caller must transform obfuscatedId string to bytes32, pure strings are not supported.
     *
     * @param  cycleId Cycle's bytes32 obfuscatedId to register.
     * @param  instructions instructions to register.
     * @param  hashlock hashlock to be set for the hybrid cycle, will be used for further checks.
     * @param  deadline Unix timestamp which is the moment the lock period will finish.
     */
    function registerCycleWithOnePeriodLock(
        bytes32 cycleId,
        InstructionMgrLib.InstructionArgs[] calldata instructions,
        bytes32 hashlock,
        uint32 deadline
    ) external requiresAuth deadlineIsLargeEnough(deadline) {
        _register(cycleId, instructions, CycleType.OnePeriodLock);

        _onePeriodLocks[cycleId].init(cycleId, hashlock, deadline);

        emit RegisterCycleWithOnePeriodLock(cycleId, instructions, hashlock);
    }

    /**
     * @notice Execute instructions in a Settlement Cycle, anyone can call this function as long as
     *         every required deposit is fulfilled.
     *
     * @param  cycleId Cycle's bytes32 obfuscatedId to execute.
     */
    function executeCycle(
        bytes32 cycleId
    ) external cycleExists(cycleId) noHybrid(cycleId) nonReentrant {
        _execute(cycleId);

        emit ExecuteCycle(cycleId);
    }

    /**
     * @notice Execute instructions in an Hybrid Settlement Cycle, anyone can call this function as long as
     *         every required deposit is fullfilled and secret is revealed.
     *
     * @param  cycleId Cycle's bytes32 obfuscatedId to execute.
     */
    function executeHybridCycle(
        bytes32 cycleId
    )
        external
        cycleExists(cycleId)
        isHybrid(cycleId)
        nonReentrant
        secretIsRevealed(cycleId)
    {
        _execute(cycleId);

        emit ExecuteHybridCycle(cycleId);
    }

    /**
     * @notice Make deposits (Native coin or ERC20 tokens) to a existent instruction, {msg.sender} will become
     *         the {sender} of the instruction hence will be the only account which is able to withdraw
     *         those allocated funds.
     *
     * @param  instructionId Instruction to allocate funds.
     */
    function deposit(
        bytes32 cycleId,
        bytes32 instructionId
    )
        external
        payable
        cycleExists(cycleId)
        belongsTo(instructionId, cycleId)
        nonReentrant
    {
        if (_cycles[cycleId].cycleType == CycleType.OnePeriodLock) {
            _onePeriodLocks[cycleId].assertIsNotExpired();
        }

        _instructions[instructionId].deposit();
    }

    /**
     * @notice Withdraw funds from a settlement. Caller must be the sender of instruction.
     *
     * @param  instructionId Instruction to withdraw deposited funds from.
     */
    function withdraw(
        bytes32 cycleId,
        bytes32 instructionId
    )
        external
        cycleExists(cycleId)
        belongsTo(instructionId, cycleId)
        nonReentrant
    {
        if (_cycles[cycleId].cycleType == CycleType.OnePeriodLock) {
            _onePeriodLocks[cycleId].assertIsNotLocked();
        } else if (_cycles[cycleId].cycleType == CycleType.PeriodicLock) {
            _periodicLocks[cycleId].assertIsNotLocked(_periodicLockConfig);
        }

        _instructions[instructionId].withdraw();
    }

    /**
     * @notice Claim locked funds from an instruction.
     * @dev    Caller must be the recipient.
     *
     * @param  instructionId Instruction to claim deposited funds.
     */
    function claim(
        bytes32 cycleId,
        bytes32 instructionId
    )
        external
        cycleExists(cycleId)
        isHybrid(cycleId)
        belongsTo(instructionId, cycleId)
        nonReentrant
        secretIsRevealed(cycleId)
    {
        _instructions[instructionId].claim();

        if (_allInstructionsClaimed(cycleId)) {
            _cycles[cycleId].executed = true;
        }
    }

    /**
     * @notice Publish the secret from a Settlement Cycle.
     * @dev    The caller can be anyone with the correct secret.
     *
     * @param  cycleId Cycle to reveal secret.
     * @param  secret  Secret to be published.
     */
    function publishSecret(
        bytes32 cycleId,
        string calldata secret
    ) external cycleExists(cycleId) isHybrid(cycleId) {
        if (_cycles[cycleId].cycleType == CycleType.OnePeriodLock) {
            _onePeriodLocks[cycleId].validateSecret(cycleId, secret);
        } else {
            // Periodic Lock
            _periodicLocks[cycleId].validateSecret(cycleId, secret);
        }
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL VIEW METHODS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice View function to get the instructions ids in a settlement cycle.
     *
     * @param cycleId Cycle to check.
     */
    function getSettlementInstructions(
        bytes32 cycleId
    ) external view cycleExists(cycleId) returns (bytes32[] memory) {
        return _cycles[cycleId].instructions;
    }

    /**
     * @notice View function to check if a cycle has been registered.
     *
     * @param cycleId Cycle to check.
     */
    function registered(bytes32 cycleId) external view returns (bool) {
        return _exists(cycleId);
    }

    /**
     * @notice View function to check if a cycle has been executed.
     *
     * @param cycleId Cycle to check.
     */
    function executed(
        bytes32 cycleId
    ) external view cycleExists(cycleId) returns (bool) {
        return _cycles[cycleId].executed;
    }

    /**
     * @notice View function to check an instruction's info
     *
     * @param instructionId Instruction to check.
     */

    function getInstructionInfo(
        bytes32 instructionId
    ) external view returns (InstructionMgrLib.Instruction memory) {
        return _instructions[instructionId];
    }

    /**
     * @notice View function to check a cycle's lock info.
     *
     * @param cycleId Cycle to get lock property from.
     */

    function getPeriodicLockInfo(
        bytes32 cycleId
    ) external view returns (PeriodicLockMgrLib.PeriodicLockInfo memory) {
        return _periodicLocks[cycleId];
    }

    /**
     * @notice View function to check a cycle's lock info.
     *
     * @param cycleId Cycle to get lock property from.
     */

    function getOnePeriodLockInfo(
        bytes32 cycleId
    ) external view returns (OnePeriodLockMgrLib.OnePeriodLockInfo memory) {
        return _onePeriodLocks[cycleId];
    }

    function periodicLockCycleIsLocked(
        bytes32 cycleId
    ) external view returns (bool) {
        return _periodicLocks[cycleId].isLocked(_periodicLockConfig);
    }

    /**
     * @notice View function to check global lock config
     */
    function periodicLockConfig()
        external
        view
        returns (uint256, uint256, uint256)
    {
        return (
            _periodicLockConfig.originTimestamp,
            _periodicLockConfig.periodInSecs / 3600,
            _periodicLockConfig.lockDurationInSecs / 3600
        );
    }

    function setPeriodicLockConfig(
        uint256 originTimestamp,
        uint256 periodInHours,
        uint256 lockDurationInHours
    ) external requiresAuth {
        PeriodicLockMgrLib.PeriodicLockConfig
            memory newConfig = PeriodicLockMgrLib.PeriodicLockConfig({
                originTimestamp: originTimestamp,
                periodInSecs: periodInHours * 3600,
                lockDurationInSecs: lockDurationInHours * 3600
            });

        // Validate new config
        if (
            newConfig.originTimestamp > block.timestamp ||
            newConfig.periodInSecs < PeriodicLockMgrLib.MIN_PERIOD_DURATION ||
            newConfig.periodInSecs > PeriodicLockMgrLib.MAX_PERIOD_DURATION ||
            newConfig.lockDurationInSecs <
            PeriodicLockMgrLib.MIN_LOCK_DURATION ||
            newConfig.lockDurationInSecs >
            newConfig.periodInSecs - PeriodicLockMgrLib.MIN_UNLOCK_DURATION
        ) {
            revert InvalidPeriodicLockConfiguration();
        }

        // Let's make sure the lock status is not changed
        bool isOldConfigLocked = PeriodicLockMgrLib.isLockedGlobal(
            _periodicLockConfig
        );

        bool isNewConfigLocked = PeriodicLockMgrLib.isLockedGlobal(newConfig);

        if (isOldConfigLocked != isNewConfigLocked) {
            revert PeriodicLockStatusChanged();
        }

        // Update config
        _periodicLockConfig = newConfig;
    }
}