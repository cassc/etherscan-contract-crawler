// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Errors {
    string constant MINT_DISABLED = "Token: Minting is disabled";
    string constant BURN_DISABLED = "Token: Burning is disabled";
    string constant MINT_ALREADY_ENABLED = "Token: Minting is already enabled";
    string constant MINT_ALREADY_DISABLED = "Token: Minting is already disabled";
    string constant BURN_ALREADY_ENABLED = "Token: Burning is already enabled";
    string constant BURN_ALREADY_DISABLED = "Token: Burning is already disabled";
    string constant NOT_ZERO_ADDRESS = "Token: Address can not be 0x0";
    string constant NOT_APPROVED = "Token: You are not approved to spend this amount of tokens";
    string constant NOT_APPROVED_TO_MANUAL_MINT = "Token: You are not approved to manual mint";
    string constant TRANSFER_EXCEEDS_BALANCE = "Token: Transfer amount exceeds balance";
    string constant BURN_EXCEEDS_BALANCE = "Token: Burn amount exceeds balance";
    string constant INSUFFICIENT_ALLOWANCE = "Token: Insufficient allowance";
    string constant NOTHING_TO_WITHDRAW = "Token: The balance must be greater than 0";
    string constant ALLOWANCE_BELOW_ZERO = "Token: Decreased allowance below zero";
    string constant ABOVE_CAP = "Token: Amount is above the cap";

    string constant NOT_OWNER = "Ownable: Caller is not the owner";
    string constant OWNABLE_NOT_ZERO_ADDRESS = "Ownable: Address can not be 0x0";

    string constant NOT_ORACLE_OR_HANDLER = "Oracle: Caller is not the oracle or handler";
    string constant ADDRESS_IS_HANDLER = "Oracle: Address is already a Bridge Handler";
    string constant ADDRESS_IS_NOT_HANDLER = "Oracle: Address is not a Bridge Handler";
    string constant TOKEN_NOT_ALLOWED_IN_BRIDGE = "Oracle: Your token is not allowed in JM Bridge";
    string constant SET_HANDLER_ORACLE_FIRST = "Oracle: Set the handler oracle address first";
    string constant ORACLE_NOT_SET = "Oracle: No oracle set";
    string constant IS_NOT_ORACLE = "Oracle: You are not the oracle";
    string constant NOT_ALLOWED_TO_EDIT_ORACLE = "Oracle: Not allowed to edit the Handler Oracle address";
    string constant NOT_ALLOWED_TO_EDIT_HANDLER = "Oracle: Not allowed to edit the Handler address";
    string constant NOT_ZERO_ADDRESS_SENDER = "Oracle: Sender can not be 0x0";
}