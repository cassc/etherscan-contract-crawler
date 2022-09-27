// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/**
 *  - VL = ValidationLogic
 *  - MATH = Math libraries

 */
library Errors {
    //common errors
    string public constant VL_EMPTY_ADDRESS = "1";
    string public constant VL_ONLY_COUNTERPARTY = "2";
    string public constant VL_LONG_PRICE_THAN_CURRENT_PRICE = "3";
    string public constant VL_SHORT_PRICE_LESS_CURRENT_PRICE = "4";
    string public constant VL_INVALID_SIZE = "6";
    string public constant VL_INVALID_ORDER_ID = "7";
    string public constant VL_EXPIRED = "8";
    string public constant VL_NOT_ENOUGH_LIQUIDITY = "9";
    string public constant VL_NOT_ENOUGH_QUOTE_FUNDING = "10";
    string public constant VL_NOT_ENOUGH_BASE_FUNDING = "11";
    string public constant VL_MUST_NOT_FILLED = "12";
    string public constant VL_SPOT_MANGER_NOT_EXITS = "13";
    string public constant VL_SPOT_MANGER_EXITS = "14";
    string public constant VL_NO_AMOUNT_TO_CLAIM = "15";
    string public constant VL_NO_LIMIT_TO_CANCEL = "16";
    string public constant VL_ONLY_OWNER = "17";
    string public constant VL_MUST_IDENTICAL_ADDRESSES = "18";
    string public constant VL_MUST_NOT_INITIALIZABLE = "19";
    string public constant VL_MUST_NOT_TOKEN_USE_RFI = "20";
    string public constant VL_ONLY_LIQUIDITY_POOL = "!LP";
    string public constant VL_NEED_MORE_BNB = "21";
    string public constant VL_MUST_CLOSE_TO_INDEX_PRICE_SHORT = "24.1";
    string public constant VL_MUST_CLOSE_TO_INDEX_PRICE_LONG = "24.2";

    // Liquidity Errors
    string public constant LQ_NO_LIQUIDITY_BASE = "30";
    string public constant LQ_NO_LIQUIDITY_QUOTE = "31";
    string public constant LQ_NO_LIQUIDITY = "32";
    string public constant LQ_POOL_EXIST = "33";
}