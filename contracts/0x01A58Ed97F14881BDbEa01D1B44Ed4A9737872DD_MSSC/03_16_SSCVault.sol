// SPDX-License-Identifier: Unlicense

pragma solidity >=0.8.4;

import "./SSCStructs.sol";
import "./Assertions.sol";
import "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import "@rari-capital/solmate/src/tokens/ERC20.sol";

/**
 * @title  Vault
 * @notice Vault contains logic for making deposits and withdrawals of funds
 *         to and from Settlements.
 */
contract SSCVault is Assertions {
    using SafeTransferLib for ERC20;

    // Events
    event Deposit(address indexed account, bytes32 instruction);
    event Withdraw(address indexed account, bytes32 instruction);

    // Track allocated funds to various instructions.
    mapping(bytes32 => uint256) internal _deposits;

    // Track sender of instruction
    mapping(bytes32 => address) internal _senderOf;

    /**
     * @notice Internal function to deposit and allocate funds to a instruction.
     *
     * @param item Contains data of the item to deposit.
     * @param instructionAmount Amount to deposit, if {item.depositType} is ETH, this
     *        parameter MUST be {msg.value}.
     */
    function _deposit(DepositItem memory item, uint256 instructionAmount)
        internal
    {
        _assertNonZeroAmount(instructionAmount, item.instructionId);
        _assertInstructionHasNoDeposits(item.instructionId);

        _deposits[item.instructionId] = instructionAmount;
        _senderOf[item.instructionId] = msg.sender;

        if (item.depositType == DepositType.ERC20) {
            ERC20 token = ERC20(item.token);

            // save in memory current balance to assert that received amount matchs required.
            uint256 vaultBalanceBeforeTransfer = token.balanceOf(address(this));

            token.safeTransferFrom(
                msg.sender,
                address(this),
                instructionAmount
            );

            uint256 vaultBalanceAfterTransfer = token.balanceOf(address(this));

            // Ensure that received amount equals required one,
            // this is useful when it comes to handling taxed ERC20 transfer.
            if (
                vaultBalanceAfterTransfer - vaultBalanceBeforeTransfer <
                instructionAmount
            ) {
                revert InvalidReceivedTokenAmount();
            }
        } else {
            if (msg.value != instructionAmount) {
                revert InvalidSuppliedETHAmount(item.instructionId);
            }
        }
        emit Deposit(msg.sender, item.instructionId);
    }

    /**
     * @notice Internal function to withdraw funds from an instruction to {msg.sender}.
     *
     * @param item Contains data of the item to withdraw.
     */
    function _withdraw(DepositItem memory item) internal {
        _assertAccountIsSender(msg.sender, item.instructionId);

        _withdrawTo(item, msg.sender);

        emit Withdraw(msg.sender, item.instructionId);
    }

    /**
     * @notice Internal to transfer allocated funds to a given account.
     *
     * @param item Contains data of the item to withdraw.
     * @param to Recipient of the withdrawal.
     */
    function _withdrawTo(DepositItem memory item, address to) internal {
        uint256 amount = _deposits[item.instructionId];
        _assertInstructionHasDeposits(item.instructionId);

        // empty deposited funds
        _deposits[item.instructionId] = 0;

        if (item.depositType == DepositType.ERC20) {
            ERC20(item.token).safeTransfer(to, amount);
        } else {
            SafeTransferLib.safeTransferETH(to, amount);
        }
    }

    // Ensure that an account is a sender of the instruction.
    function _assertAccountIsSender(address account, bytes32 instructionId)
        private
        view
    {
        // Revert if {account} is not sender.
        if (_senderOf[instructionId] != account) {
            revert NotASender(instructionId);
        }
    }

    // Ensure that required amount in a instruction is fullfiled.
    function _assertInstructionHasDeposits(bytes32 instructionId) private view {
        // Revert if the supplied amount is equal to zero.
        if (_deposits[instructionId] == 0) {
            revert NoDeposits(instructionId);
        }
    }

    // Ensure that required amount in a instruction is fullfiled.
    function _assertInstructionHasNoDeposits(bytes32 instructionId)
        private
        view
    {
        // Revert if the supplied amount is not equal to zero.
        if (_deposits[instructionId] != 0) {
            revert AlreadyDeposited(instructionId);
        }
    }
}