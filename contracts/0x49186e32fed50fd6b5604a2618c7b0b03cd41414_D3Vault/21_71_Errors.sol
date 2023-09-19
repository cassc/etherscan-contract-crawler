// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

library Errors {
    string public constant POOL_ALREADY_ADDED = "D3VAULT_POOL_ALREADY_ADDED";
    string public constant POOL_NOT_ADDED = "D3VAULT_POOL_NOT_ADDED";
    string public constant HAS_POOL_PENDING_REMOVE = "D3VAULT_HAS_POOL_PENDING_REMOVE";
    string public constant AMOUNT_EXCEED_VAULT_BALANCE = "D3VAULT_AMOUNT_EXCEED_VAULT_BALANCE";
    string public constant NOT_ALLOWED_ROUTER = "D3VAULT_NOT_ALLOWED_ROUTER";
    string public constant NOT_ALLOWED_LIQUIDATOR = "D3VAULT_NOT_ALLOWED_LIQUIDATOR";
    string public constant NOT_PENDING_REMOVE_POOL = "D3VAULT_NOT_PENDING_REMOVE_POOL";
    string public constant NOT_D3POOL = "D3VAULT_NOT_D3POOL";
    string public constant NOT_ALLOWED_TOKEN = "D3VAULT_NOT_ALLOWED_TOKEN";
    string public constant NOT_D3_FACTORY = "D3VAULT_NOT_D3_FACTORY";
    string public constant TOKEN_ALREADY_EXIST = "D3VAULT_TOKEN_ALREADY_EXIST";
    string public constant TOKEN_NOT_EXIST = "D3VAULT_TOKEN_NOT_EXIST";
    string public constant WRONG_WEIGHT = "D3VAULT_WRONG_WEIGHT";
    string public constant WRONG_RESERVE_FACTOR = "D3VAULT_RESERVE_FACTOR";
    string public constant WITHDRAW_AMOUNT_EXCEED = "D3VAULT_WITHDRAW_AMOUNT_EXCEED";
    string public constant MAINTAINER_NOT_SET = "D3VAULT_MAINTAINER_NOT_SET";

    // ---------- funding ----------
    string public constant EXCEED_QUOTA = "D3VAULT_EXCEED_QUOTA";
    string public constant EXCEED_MAX_DEPOSIT_AMOUNT = "D3VAULT_EXCEED_MAX_DEPOSIT_AMOUNT";
    string public constant DTOKEN_BALANCE_NOT_ENOUGH = "D3TOKEN_BALANCE_NOT_ENOUGH";
    string public constant POOL_NOT_SAFE = "D3VAULT_POOL_NOT_SAFE";
    string public constant NOT_ENOUGH_COLLATERAL_FOR_BORROW = "D3VAULT_NOT_ENOUGH_COLLATERAL_FOR_BORROW";
    string public constant AMOUNT_EXCEED = "D3VAULT_AMOUNT_EXCEED";
    string public constant NOT_RATE_MANAGER = "D3VAULT_NOT_RATE_MANAGER";

    // ---------- liquidation ----------
    string public constant COLLATERAL_AMOUNT_EXCEED = "D3VAULT_COLLATERAL_AMOUNT_EXCEED";
    string public constant CANNOT_BE_LIQUIDATED = "D3VAULT_CANNOT_BE_LIQUIDATED";
    string public constant INVALID_COLLATERAL_TOKEN = "D3VAULT_INVALID_COLLATERAL_TOKEN";
    string public constant INVALID_DEBT_TOKEN = "D3VAULT_INVALID_DEBT_TOKEN";
    string public constant DEBT_TO_COVER_EXCEED = "D3VAULT_DEBT_TO_COVER_EXCEED";
    string public constant ALREADY_IN_LIQUIDATION = "D3VAULT_ALREADY_IN_LIQUIDATION";
    string public constant STILL_UNDER_MM = "D3VAULT_STILL_UNDER_MM";
    string public constant NO_BAD_DEBT = "D3VAULT_NO_BAD_DEBT";
    string public constant NOT_IN_LIQUIDATION = "D3VAULT_NOT_IN_LIQUIDATION";
    string public constant EXCEED_DISCOUNT = "D3VAULT_EXCEED_DISCOUNT";
    string public constant LIQUIDATION_NOT_DONE = "D3VAULT_LIQUIDATION_NOT_DONE";
    string public constant HAS_BAD_DEBT = "D3VAULT_HAS_BAD_DEBT";
}