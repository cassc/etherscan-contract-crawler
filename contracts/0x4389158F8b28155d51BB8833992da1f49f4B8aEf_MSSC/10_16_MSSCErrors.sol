// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

/**
 * @title MSSCErrors
 */
interface MSSCErrors {
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
     * @dev Revert with an error when trying to register an existent instruction.
     *
     * @param instruction The instruction that already exists.
     *
     */
    error InstructionExists(bytes32 instruction);

    /**
     * @dev Revert with an error when attempting to interact with an instruction that
     *      does not yet exist.
     *
     * @param instruction The instruction that doesn't exist.
     */
    error NoInstruction(bytes32 instruction);

    /**
     * @dev Revert with an error when an asset of a instruction is invalid.
     *
     * @param instruction The instruction that contain the invalid asset.
     */
    error InvalidAsset(bytes32 instruction);

    /**
     * @dev Revert with an error when attempting to register a receiver account
     *      and supplying the null address.
     *
     * @param instruction The instruction that contain the zero address.
     */
    error ReceiverIsZeroAddress(bytes32 instruction);

    /**
     * @dev Revert with an error when invalid ether is deposited for an instruction.
     *
     * @param instruction  The instruction identifier of the attempted operation.
     */
    error InvalidSuppliedETHAmount(bytes32 instruction);

    /**
     * @dev Revert with an error when received ERC20 token amount is not enough for an amount.
     *
     */
    error InvalidReceivedTokenAmount();

    /**
     * @dev Revert with an error when an account is not a sender the instruction.
     *
     * @param instruction  The instruction identifier of the attempted operation.
     */
    error NotASender(bytes32 instruction);

    /**
     * @dev Revert with an error when attempting to register a Settlement with no amount.
     *
     * @param instruction  The instruction identifier of the attempted operation.
     */
    error ZeroAmount(bytes32 instruction);

    /**
     * @dev Revert with an error when a instruction has no deposits.
     *
     * @param instruction  The instruction identifier of the attempted operation.
     */
    error NoDeposits(bytes32 instruction);

    /**
     * @dev Revert with an error when a instruction has deposits.
     *
     * @param instruction  The instruction identifier of the attempted operation.
     */
    error AlreadyDeposited(bytes32 instruction);
}