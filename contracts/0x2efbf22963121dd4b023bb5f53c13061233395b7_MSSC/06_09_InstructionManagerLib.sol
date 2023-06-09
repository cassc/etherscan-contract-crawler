// SPDX-License-Identifier: Unlicense

pragma solidity >=0.8.4;

import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";

/**
 * @title   InstructionManagerLib
 * @notice  Contains logic for managing instructions such as
 *          registration, deposits, withdrawals and payments.
 */

library InstructionManagerLib {
    using SafeTransferLib for ERC20;

    event Deposit(address indexed account, bytes32 instruction);
    event Withdraw(address indexed account, bytes32 instruction);
    event Claim(bytes32 instruction);

    enum DepositStatus {
        PENDING,
        AVAILABLE,
        CLAIMED
    }

    struct InstructionArgs {
        bytes32 id;
        address receiver;
        address asset;
        uint256 amount;
    }

    struct Instruction {
        bytes32 id;
        address recipient;
        address asset;
        uint256 amount;
        address payer;
        DepositStatus depositStatus;
    }

    /**
     * @dev    Validate and register instruction data.
     *
     * @param  sInstruction Storage pointer where data will be saved.
     * @param  instructionArgs data to register.
     */

    function register(
        Instruction storage sInstruction,
        InstructionArgs calldata instructionArgs
    ) internal {
        // Copy values to memory so that we save extra SLOADs
        Instruction memory instruction = sInstruction;

        // Ensure that instruction doesn't exist by checking its amount.
        if (instruction.amount > 0) {
            revert InstructionExists(instructionArgs.id);
        }

        _assertValidInstructionData(instructionArgs);

        sInstruction.id = instructionArgs.id;
        sInstruction.recipient = instructionArgs.receiver;
        sInstruction.amount = instructionArgs.amount;
        sInstruction.asset = instructionArgs.asset;
    }

    /**
     * @dev    Fulfill a instruction's required amount by depositing into the MSSC contract.
     *
     * @param  sInstruction Instruction to make the deposit.
     */
    function deposit(Instruction storage sInstruction) internal {
        // Copy values to memory so that we save extra SLOADs
        Instruction memory mInstruction = sInstruction;

        // Ensure that instruction does exist by checking its amount.
        if (mInstruction.amount == 0) {
            revert NoInstruction();
        }

        // Revert if the is not awaiting deposits
        if (mInstruction.depositStatus != DepositStatus.PENDING) {
            revert AlreadyFulfilled(mInstruction.id, mInstruction.payer);
        }

        sInstruction.depositStatus = DepositStatus.AVAILABLE;
        sInstruction.payer = msg.sender;

        // is not native ETH
        _performTransfer(
            mInstruction.asset,
            msg.sender,
            address(this),
            mInstruction.amount
        );

        emit Deposit(msg.sender, mInstruction.id);
    }

    /**
     * @dev    Withdraw funds previously deposited to an instruction, {msg.sender} must be the payer.
     *
     * @param  sInstruction Instruction to withdraw funds from.
     */
    function withdraw(Instruction storage sInstruction) internal {
        // Copy values to memory so that we save extra SLOADs
        Instruction memory mInstruction = sInstruction;

        if (mInstruction.payer != msg.sender) {
            revert NotPayer();
        }
        _assertFundsAreAvailable(mInstruction);

        // revert deposit status
        sInstruction.depositStatus = DepositStatus.PENDING;

        _performTransfer(
            mInstruction.asset,
            address(this),
            mInstruction.payer,
            mInstruction.amount
        );

        emit Withdraw(msg.sender, mInstruction.id);
    }

    /**
     * @dev    Pay allocated funds to its corresponding recipient.
     *
     * @param  sInstruction Instruction to withdraw funds from.
     */

    function claim(Instruction storage sInstruction) internal {
        // Copy values to memory so that we save extra SLOADs
        Instruction memory mInstruction = sInstruction;

        _assertFundsAreAvailable(mInstruction);

        // update status to claimed
        sInstruction.depositStatus = DepositStatus.CLAIMED;

        _performTransfer(
            mInstruction.asset,
            address(this),
            mInstruction.recipient,
            mInstruction.amount
        );

        emit Claim(mInstruction.id);
    }

    /*//////////////////////////////////////////////////////////////
                           TRANSFER HELPERS
    //////////////////////////////////////////////////////////////*/

    // Perform a transfer of funds from one address to another.
    //
    // NOTE: This function performs checks to ensure that the correct amount of
    //       funds are transferred. If the amount transferred is not equal to the
    //       expected amount, the transaction will be reverted. This is to
    //       prevent tokens with a transfer fee from being used.
    function _performTransfer(
        address asset,
        address from,
        address to,
        uint256 amount
    ) private {
        // is not native ETH
        if (asset != address(0)) {
            uint256 balanceBefore = ERC20(asset).balanceOf(to);

            if (from == address(this)) {
                ERC20(asset).safeTransfer(to, amount);
            } else {
                ERC20(asset).safeTransferFrom(from, to, amount);
            }

            uint256 balanceAfter = ERC20(asset).balanceOf(to);

            uint256 actualAmount = balanceAfter - balanceBefore;

            // Revert if the received amount don't match the expected amount
            if (actualAmount != amount) {
                revert UnexpectedReceivedAmount(asset, amount, actualAmount);
            }
        } else {
            if (from != address(this)) {
                if (msg.value != amount) {
                    revert InvalidSuppliedETHAmount();
                }
            } else {
                SafeTransferLib.safeTransferETH(to, amount);
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                           ASSERTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Ensure that required amount in a instruction is fullfiled.
     */
    function _assertFundsAreAvailable(
        Instruction memory instruction
    ) private pure {
        // Revert if there's no deposits
        if (
            instruction.depositStatus != DepositStatus.AVAILABLE ||
            instruction.payer == address(0)
        ) {
            revert NoDeposits(instruction.id);
        }
    }

    /**
     * @dev Internal view function to ensure that a given instruction tuple has valid data.
     *
     * @param instruction  The instruction tuple to check.
     */

    function _assertValidInstructionData(
        InstructionArgs calldata instruction
    ) internal view {
        _assertNonZeroAmount(instruction);

        _assertReceiverIsNotZeroAddress(instruction);

        _assertValidAsset(instruction);
    }

    /**
     * @dev Internal pure function to ensure that a given item amount is not
     *      zero.
     *
     * @param instruction  The instruction tuple to check.
     */
    function _assertNonZeroAmount(
        InstructionArgs calldata instruction
    ) internal pure {
        // Revert if the supplied amount is equal to zero.
        if (instruction.amount == 0) {
            revert ZeroAmount(instruction.id);
        }
    }

    /**
     * @dev Internal view function to ensure that {sender} and {recipient} in a given
     *      instruction are non-zero addresses.
     *
     * @param instruction  The instruction tuple to check.
     */
    function _assertReceiverIsNotZeroAddress(
        InstructionArgs calldata instruction
    ) private pure {
        if (instruction.receiver == address(0)) {
            revert ReceiverIsZeroAddress(instruction.id);
        }
    }

    /**
     * @dev Internal view function to ensure that {asset} is a valid contract or null address
     *      for ETH transfers.
     *
     * @param instruction  The instruction tuple to check.
     */
    function _assertValidAsset(
        InstructionArgs calldata instruction
    ) private view {
        if (
            instruction.asset.code.length == 0 &&
            instruction.asset != address(0)
        ) {
            revert InvalidAsset(instruction.id);
        }
    }

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Revert with an error when attempting to interact with an instruction that
     *      does not yet exist.
     */
    error NoInstruction();

    /**
     * @dev Revert with an error when trying to register an existent instruction.
     *
     * @param instruction The instruction that already exists.
     *
     */
    error InstructionExists(bytes32 instruction);

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
     * @dev Revert with an error when {msg.value} does not match the required ETH amount
     *      required by an instruction.
     */
    error InvalidSuppliedETHAmount();

    /**
     * @dev Revert with an error when an account is not the payer of the instruction.
     */
    error NotPayer();

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
     * @param payer        The address which deposited and fulfilled the intruction's amount.
     */
    error AlreadyFulfilled(bytes32 instruction, address payer);

    /**
     * @dev Revert with an error if the received amount don't match the expected amount.
     */
    error UnexpectedReceivedAmount(
        address asset,
        uint256 expected,
        uint256 actual
    );
}