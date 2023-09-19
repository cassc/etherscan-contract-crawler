// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

library Errors {
    // ============= pool funding state =================
    string public constant NOT_SAFE = "D3MM_NOT_SAFE";
    string public constant NOT_BORROW_SAFE = "D3MM_NOT_BORROW_SAFE";
    string public constant NOT_VAULT = "D3MM_NOT_VAULT";
    string public constant NOT_IN_LIQUIDATION = "D3MM_NOT_IN_LIQUIDATION";
    string public constant POOL_NOT_ONGOING = "D3MM_POOL_NOT_ONGOING";
    string public constant TOKEN_NOT_FEASIBLE = "D3MM_TOKEN_NOT_FEASIBLE";

    // ============== pool trade =======================
    string public constant BALANCE_NOT_ENOUGH = "D3MM_BALANCE_NOT_ENOUGH";
    string public constant AMOUNT_TOO_SMALL = "D3MM_AMOUNT_TOO_SMALL";
    string public constant FROMAMOUNT_NOT_ENOUGH = "D3MM_FROMAMOUNT_NOT_ENOUGH";
    string public constant MINRES_NOT_ENOUGH = "D3MM_MINRESERVE_NOT_ENOUGH";
    string public constant MAXPAY_NOT_ENOUGH = "D3MM_MAXPAYAMOUNT_NOT_ENOUGH";
    string public constant BELOW_IM_RATIO = "D3MM_BELOW_IM_RATIO";
    string public constant HEARTBEAT_CHECK_FAIL = "D3MM_HEARTBEAT_CHECK_FAIL";

    // =============== d3 maker =========================
    string public constant K_LIMIT = "D3MAKER_K_LIMIT_ERROR";
    string public constant PRICE_UP_BELOW_PRICE_DOWN = "D3MAKER_PRICE_UP_BELOW_PRICE_DOWN";
    string public constant HAVE_SET_TOKEN_INFO = "D3MAKER_HAVE_SET_TOKEN_INFO";
    string public constant K_LENGTH_NOT_MATCH = "D3MAKER_K_LENGTH_NOT_MATCH";
    string public constant AMOUNTS_LENGTH_NOT_MATCH = "D3MAKER_AMOUNTS_LENGTH_NOT_MATCH";
    string public constant PRICES_LENGTH_NOT_MATCH = "D3MAKER_PRICES_LENGTH_NOT_MATCH";
    string public constant PRICE_SLOT_LENGTH_NOT_MATCH = "D3MAKER_PRICE_SLOT_LENGTH_NOT_MATCH";
    string public constant INVALID_TOKEN = "D3MAKER_INVALID_TOKEN";

    // =============== pmmRangeOrder ====================
    string public constant RO_ORACLE_PROTECTION = "PMMRO_ORACLE_PRICE_PROTECTION";
    string public constant RO_VAULT_RESERVE = "PMMRO_VAULT_RESERVE_NOT_ENOUGH";
    string public constant RO_AMOUNT_ZERO = "PMMRO_AMOUNT_ZERO";
    string public constant RO_PRICE_ZERO = "PMMRO_PRICE_ZERO";
    string public constant RO_PRICE_DIFF_TOO_SMALL = "PMMRO_PRICE_DIFF_TOO_SMALL";

    
}