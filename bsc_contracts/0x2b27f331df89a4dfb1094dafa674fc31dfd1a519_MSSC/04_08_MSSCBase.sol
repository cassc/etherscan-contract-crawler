//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../lib/PeriodicLockManagerLib.sol";
import "../lib/OnePeriodLockManagerLib.sol";
import "../lib/InstructionManagerLib.sol";

enum CycleType {
    Unlocked,
    PeriodicLock,
    OnePeriodLock
}

abstract contract MSSCBase {
    using InstructionManagerLib for InstructionManagerLib.Instruction;
    using PeriodicLockManagerLib for PeriodicLockManagerLib.PeriodicLockInfo;
    using OnePeriodLockManagerLib for OnePeriodLockManagerLib.OnePeriodLockInfo;

    event RegisterCycle(
        bytes32 indexed cycleId,
        InstructionManagerLib.InstructionArgs[] instructions
    );
    event RegisterCycleWithPeriodicLocks(
        bytes32 indexed cycleId,
        InstructionManagerLib.InstructionArgs[] instructions,
        bytes32 hashlock
    );
    event RegisterCycleWithOnePeriodLock(
        bytes32 indexed cycleId,
        InstructionManagerLib.InstructionArgs[] instructions,
        bytes32 hashlock
    );

    event ExecuteCycle(bytes32 indexed cycleId);
    event ExecuteHybridCycle(bytes32 indexed cycleId);

    modifier cycleExists(bytes32 cycleId) {
        if (!_exists(cycleId)) {
            revert NoCycle();
        }
        _;
    }

    modifier isHybrid(bytes32 cycleId) {
        if (!_isHybrid(cycleId)) {
            revert NotHybrid();
        }

        _;
    }

    modifier isLocked(bytes32 cycleId) {
        if (_cycles[cycleId].cycleType == CycleType.OnePeriodLock) {
            _onePeriodLocks[cycleId].assertIsLocked();
        } else if (_cycles[cycleId].cycleType == CycleType.PeriodicLock) {
            _periodicLocks[cycleId].assertIsLockedPeriod(_periodicLockConfig);
        }

        _;
    }

    modifier noHybrid(bytes32 cycleId) {
        if (_isHybrid(cycleId)) {
            revert HybridCycle();
        }

        _;
    }

    modifier secretIsRevealed(bytes32 cycleId) {
        if (_cycles[cycleId].cycleType == CycleType.OnePeriodLock) {
            _onePeriodLocks[cycleId].assertSecretIsRevealed();
        } else if (_cycles[cycleId].cycleType == CycleType.PeriodicLock) {
            _periodicLocks[cycleId].assertSecretIsRevealed();
        }

        _;
    }

    struct SettlementCycle {
        bytes32[] instructions;
        CycleType cycleType;
        bool executed;
    }

    mapping(bytes32 => SettlementCycle) internal _cycles;
    mapping(bytes32 => PeriodicLockManagerLib.PeriodicLockInfo)
        internal _periodicLocks;
    mapping(bytes32 => OnePeriodLockManagerLib.OnePeriodLockInfo)
        internal _onePeriodLocks;
    mapping(bytes32 => InstructionManagerLib.Instruction)
        internal _instructions;

    PeriodicLockManagerLib.PeriodicLockConfig internal _periodicLockConfig;

    constructor() {
        // Reference: Mon Jan 02 2023 00:00:00 GMT+0000
        _periodicLockConfig.originTimestamp = 1672617600;
        _periodicLockConfig.periodInHours = 7 days;
        _periodicLockConfig.lockDurationInHours = 4 days;
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HELPERS
    //////////////////////////////////////////////////////////////*/

    function _register(
        bytes32 cycleId,
        InstructionManagerLib.InstructionArgs[] calldata instructions,
        CycleType cycleType
    ) internal {
        if (_exists(cycleId)) {
            revert CycleAlreadyRegistered();
        }

        // Retrieve the total number of instructions and place on the stack.
        uint256 totalInstructions = instructions.length;

        if (totalInstructions == 0) {
            revert CycleHasNoInstruction();
        }

        _cycles[cycleId].cycleType = cycleType;
        bytes32[] storage newInstructions = _cycles[cycleId].instructions;

        for (uint256 i = 0; i < totalInstructions; ) {
            InstructionManagerLib.InstructionArgs
                calldata instructionArgs = instructions[i];

            bytes32 instructionId = instructionArgs.id;

            InstructionManagerLib.Instruction
                storage instruction = _instructions[instructionId];

            instruction.register(instructionArgs);

            newInstructions.push(instructionId);

            // Skip overflow check as for loop is indexed starting at zero.
            unchecked {
                ++i;
            }
        }
    }

    function _execute(bytes32 cycleId) internal {
        if (_cycles[cycleId].executed) revert CycleAlreadyExecuted();

        _cycles[cycleId].executed = true;
        bytes32[] memory instructions = _cycles[cycleId].instructions;

        // Retrieve the total number of instructions and place on the stack.
        uint256 totalInstructions = instructions.length;

        for (uint256 i = 0; i < totalInstructions; ) {
            InstructionManagerLib.Instruction
                storage instruction = _instructions[instructions[i]];

            // Ignore claimed instructions, this comes handy when dealing with hybrid Settlement Cycles.
            if (
                instruction.depositStatus !=
                InstructionManagerLib.DepositStatus.CLAIMED
            ) {
                instruction.claim();
            }

            // Skip overflow check as for loop is indexed starting at zero.
            unchecked {
                ++i;
            }
        }
    }

    function _exists(bytes32 cycleId) internal view returns (bool) {
        return _cycles[cycleId].instructions.length > 0;
    }

    function _allInstructionsFulfilled(
        bytes32 cycleId
    ) internal view returns (bool) {
        return
            _allInstructionsMatchStatus(
                cycleId,
                InstructionManagerLib.DepositStatus.AVAILABLE
            );
    }

    function _allInstructionsClaimed(
        bytes32 cycleId
    ) internal view returns (bool) {
        return
            _allInstructionsMatchStatus(
                cycleId,
                InstructionManagerLib.DepositStatus.CLAIMED
            );
    }

    function _allInstructionsMatchStatus(
        bytes32 cycleId,
        InstructionManagerLib.DepositStatus status
    ) private view returns (bool) {
        uint256 instructionsCount = _cycles[cycleId].instructions.length;

        for (uint256 i = 0; i < instructionsCount; ) {
            if (
                _instructions[_cycles[cycleId].instructions[i]].depositStatus !=
                status
            ) return false;

            unchecked {
                ++i;
            }
        }

        return true;
    }

    function _isHybrid(bytes32 cycleId) internal view returns (bool) {
        return _cycles[cycleId].cycleType != CycleType.Unlocked;
    }

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Revert with an error when trying to register an existent Settlement Cycle.
     */
    error CycleAlreadyRegistered();

    /**
     * @dev Revert with an error when executing a previously executed Settlement Cycle.
     */
    error CycleAlreadyExecuted();

    /**
     * @dev Revert with an error when attempting to interact with a cycle that
     *      does not yet exist.
     */
    error NoCycle();

    /**
     * @dev Revert with an error when attempting to register a cycle without a
     *      single instruction.
     */
    error CycleHasNoInstruction();

    /**
     * @dev Revert with an error when attempting to perform Hybrid logic in a normal cycle.
     */
    error NotHybrid();

    /**
     * @dev Revert with an error when attempting to perform invalid logic in an Hybrid cycle.
     */
    error HybridCycle();
}