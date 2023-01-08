// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.15;

interface IWithdrawableInternal {
    enum Mode {
        OWNER,
        RECIPIENT,
        ANYONE,
        NOBODY
    }

    error ErrWithdrawOnlyRecipient();
    error ErrWithdrawOnlyOwner();
    error ErrWithdrawImpossible();
    error ErrWithdrawRecipientLocked();
    error ErrWithdrawModeLocked();
    error ErrWithdrawRecipientNotSet();

    event WithdrawRecipientChanged(address indexed recipient);
    event WithdrawRecipientLocked();
    event WithdrawModeChanged(Mode _mode);
    event WithdrawModeLocked();
    event Withdrawn(address[] claimTokens, uint256[] amounts);
    event WithdrawPowerRevoked();
}