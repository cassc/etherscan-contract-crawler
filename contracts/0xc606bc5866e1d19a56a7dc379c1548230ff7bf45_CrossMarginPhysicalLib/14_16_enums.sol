// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum TokenType {
    PUT,
    CALL
}

/**
 * @dev common action types on margin engines
 */
enum ActionType {
    AddCollateral,
    RemoveCollateral,
    MintShort,
    BurnShort,
    AddLong,
    RemoveLong,
    ExerciseToken,
    SettleAccount,
    // actions that influence more than one subAccounts:
    // These actions are defined in "OptionTransferable"
    MintShortIntoAccount, // increase short (debt) position in one subAccount, increase long token directly to another subAccount
    TransferCollateral, // transfer collateral directly to another subAccount
    TransferLong, // transfer long directly to another subAccount
    TransferShort // transfer short directly to another subAccount
}