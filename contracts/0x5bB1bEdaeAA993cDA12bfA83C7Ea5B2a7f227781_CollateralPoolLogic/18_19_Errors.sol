// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library Errors {
    string public constant LEDGER_INITIALIZED = 'LEDGER_INITIALIZED';
    string public constant CALLER_NOT_OPERATOR = 'CALLER_NOT_OPERATOR';
    string public constant CALLER_NOT_LIQUIDATE_EXECUTOR = 'CALLER_NOT_LIQUIDATE_EXECUTOR';
    string public constant CALLER_NOT_CONFIGURATOR = 'CALLER_NOT_CONFIGURATOR';
    string public constant CALLER_NOT_WHITELISTED = 'CALLER_NOT_WHITELISTED';
    string public constant CALLER_NOT_LEDGER = 'ONLY_LEDGER';
    string public constant INVALID_LEVERAGE_FACTOR = 'INVALID_LEVERAGE_FACTOR';
    string public constant INVALID_LIQUIDATION_RATIO = 'INVALID_LIQUIDATION_RATIO';
    string public constant INVALID_TRADE_FEE = 'INVALID_TRADE_FEE';
    string public constant INVALID_ZERO_ADDRESS = 'INVALID_ZERO_ADDRESS';
    string public constant INVALID_ASSET_CONFIGURATION = 'INVALID_ASSET_CONFIGURATION';
    string public constant ASSET_INACTIVE = 'ASSET_INACTIVE';
    string public constant ASSET_ACTIVE = 'ASSET_ACTIVE';
    string public constant POOL_INACTIVE = 'POOL_INACTIVE';
    string public constant POOL_ACTIVE = 'POOL_ACTIVE';
    string public constant POOL_EXIST = 'POOL_EXIST';
    string public constant INVALID_POOL_REINVESTMENT = 'INVALID_POOL_REINVESTMENT';
    string public constant ASSET_INITIALIZED = 'ASSET_INITIALIZED';
    string public constant ASSET_NOT_INITIALIZED = 'ASSET_NOT_INITIALIZED';
    string public constant POOL_INITIALIZED = 'POOL_INITIALIZED';
    string public constant POOL_NOT_INITIALIZED = 'POOL_NOT_INITIALIZED';
    string public constant INVALID_ZERO_AMOUNT = 'INVALID_ZERO_AMOUNT';
    string public constant CANNOT_SWEEP_REGISTERED_ASSET = 'CANNOT_SWEEP_REGISTERED_ASSET';
    string public constant INVALID_ACTION_ID = 'INVALID_ACTION_ID';
    string public constant INVALID_POSITION_TYPE = 'INVALID_POSITION_TYPE';
    string public constant INVALID_AMOUNT_INPUT = 'INVALID_AMOUNT_INPUT';
    string public constant INVALID_ASSET_INPUT = 'INVALID_ASSET_INPUT';
    string public constant INVALID_SWAP_BUFFER_LIMIT = 'INVALID_SWAP_BUFFER_LIMIT';
    string public constant NOT_ENOUGH_BALANCE = 'NOT_ENOUGH_BALANCE';
    string public constant NOT_ENOUGH_LONG_BALANCE = 'NOT_ENOUGH_LONG_BALANCE';
    string public constant NOT_ENOUGH_POOL_BALANCE = 'NOT_ENOUGH_POOL_BALANCE';
    string public constant NOT_ENOUGH_USER_LEVERAGE = 'NOT_ENOUGH_USER_LEVERAGE';
    string public constant MISSING_UNDERLYING_ASSET = 'MISSING_UNDERLYING_ASSET';
    string public constant NEGATIVE_PNL = 'NEGATIVE_PNL';
    string public constant NEGATIVE_AVAILABLE_LEVERAGE = 'NEGATIVE_AVAILABLE_LEVERAGE';
    string public constant BAD_TRADE = 'BAD_TRADE';
    string public constant USER_TRADE_BLOCK = 'USER_TRADE_BLOCK';
    string public constant ERROR_EMERGENCY_WITHDRAW = 'ERROR_EMERGENCY_WITHDRAW';
    string public constant ERROR_UNWRAP_LP = 'ERROR_UNWRAP_LP';
    string public constant CANNOT_TRADE_SAME_ASSET = 'CANNOT_TRADE_SAME_ASSET';
    string public constant ASSET_CANNOT_SHORT = 'ASSET_CANNOT_SHORT';
    string public constant ASSET_CANNOT_LONG = 'ASSET_CANNOT_LONG';
}