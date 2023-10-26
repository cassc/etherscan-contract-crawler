// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/**
 * @dev common action types on margin engines
 *      these constants are defined to add compatibility between ActionTypes of physical and cash settled margin engines
 *      uint8 values correspond to the order (and value) of the enum entries
 */

// actions that are aligned in both enums and use the same uint8 representation between engines
uint8 constant ADD_COLLATERAL_ACTION = 0;
uint8 constant REMOVE_COLLATERAL_ACTION = 1;
uint8 constant MINT_SHORT_ACTION = 2;
uint8 constant BURN_SHORT_ACTION = 3;

// actions that have misaligned order in enums of physical and cash engines
uint8 constant PHYSICAL_ADD_LONG_ACTION = 4;
uint8 constant CASH_ADD_LONG_ACTION = 6;

uint8 constant PHYSICAL_REMOVE_LONG_ACTION = 5;
uint8 constant CASH_REMOVE_LONG_ACTION = 7;

uint8 constant PHYSICAL_SETTLE_ACCOUNT_ACTION = 7;
uint8 constant CASH_SETTLE_ACCOUNT_ACTION = 8;

uint8 constant PHYSICAL_MINT_SHORT_INTO_ACCOUNT_ACTION = 8; // increase short (debt) position in one subAccount, increase long token directly to another subAccount
uint8 constant CASH_MINT_SHORT_INTO_ACCOUNT_ACTION = 9; // increase short (debt) position in one subAccount, increase long token directly to another subAccount

uint8 constant PHYSICAL_TRANSFER_COLLATERAL_ACTION = 9; // transfer collateral directly to another subAccount
uint8 constant CASH_TRANSFER_COLLATERAL_ACTION = 10; // transfer collateral directly to another subAccount

uint8 constant PHYSICAL_TRANSFER_LONG_ACTION = 10; // transfer long directly to another subAccount
uint8 constant CASH_TRANSFER_LONG_ACTION = 11; // transfer long directly to another subAccount

uint8 constant PHYSICAL_TRANSFER_SHORT_ACTION = 11;
uint8 constant CASH_TRANSFER_SHORT_ACTION = 12;

// additional action that is only used in the physical engine:
uint8 constant EXERCISE_TOKEN_ACTION = 6;

uint256 constant UNIT = 1e6;