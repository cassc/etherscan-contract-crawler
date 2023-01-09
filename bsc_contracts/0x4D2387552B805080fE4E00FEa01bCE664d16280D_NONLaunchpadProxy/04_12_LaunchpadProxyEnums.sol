// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

library LaunchpadProxyEnums {
    // 'ok'
    string public constant OK = "0";
    // 'only collaborator,owner can call'
    string public constant LPD_ONLY_COLLABORATOR_OWNER = "1";
    // 'only controller,collaborator,owner'
    string public constant LPD_ONLY_CONTROLLER_COLLABORATOR_OWNER = "2";
    // 'only authorities can call'
    string public constant LPD_ONLY_AUTHORITIES_ADDRESS = "3";
    // seprator err
    string public constant LPD_SEPARATOR = "4";
    // 'sender must transaction caller'
    string public constant SENDER_MUST_TX_CALLER = "5";
    // 'launchpad invalid id'
    string public constant LPD_INVALID_ID = "6";
    // 'launchpadId exists'
    string public constant LPD_ID_EXISTS = "7";
    // 'launchpad not enable'
    string public constant LPD_NOT_ENABLE = "8";
    // 'input array len not match'
    string public constant LPD_INPUT_ARRAY_LEN_NOT_MATCH = "9";
    // 'launchpad param locked'
    string public constant LPD_PARAM_LOCKED = "10";
    // 'launchpad rounds idx invalid'
    string public constant LPD_ROUNDS_IDX_INVALID = "11";
    // 'max supply invalid'
    string public constant LPD_ROUNDS_MAX_SUPPLY_INVALID = "12";
    // 'initial sale quantity must 0'
    string public constant LPD_ROUNDS_SALE_QUANTITY = "13";
    // "rounds target contract address not valid"
    string public constant LPD_ROUNDS_TARGET_CONTRACT_INVALID = "14";
    // "invalid abi selector array not equal max"
    string public constant LPD_ROUNDS_ABI_ARRAY_LEN = "15";
    // "max buy qty invalid"
    string public constant LPD_ROUNDS_MAX_BUY_QTY_INVALID = "16";
    // 'flag array len not equal max'
    string public constant LPD_ROUNDS_FLAGS_ARRAY_LEN = "17";
    // 'buy from contract address not allowed'
    string public constant LPD_ROUNDS_BUY_FROM_CONTRACT_NOT_ALLOWED = "18";
    // 'sale not start yet'
    string public constant LPD_ROUNDS_SALE_NOT_START = "19";
    // 'max buy quantity one transaction limit'
    string public constant LPD_ROUNDS_MAX_BUY_QTY_PER_TX_LIMIT = "20";
    // 'quantity not enough to buy'
    string public constant LPD_ROUNDS_QTY_NOT_ENOUGH_TO_BUY = "21";
    // "payment not enough"
    string public constant LPD_ROUNDS_PAYMENT_NOT_ENOUGH = "22";
    // 'allowance not enough'
    string public constant LPD_ROUNDS_PAYMENT_ALLOWANCE_NOT_ENOUGH = "23";
    // "account max buy num limit"
    string public constant LPD_ROUNDS_ACCOUNT_MAX_BUY_LIMIT = "24";
    // 'account buy interval limit'
    string public constant LPD_ROUNDS_ACCOUNT_BUY_INTERVAL_LIMIT = "25";
    // 'not in whitelist'
    string public constant LPD_ROUNDS_ACCOUNT_NOT_IN_WHITELIST = "26";
    // 'buy selector invalid '
    string public constant LPD_ROUNDS_ABI_BUY_SELECTOR_INVALID = "27";
    // 'sale time invalid'
    string public constant LPD_ROUNDS_SALE_START_TIME_INVALID = "28";
    // 'price must > 0'
    string public constant LPD_ROUNDS_PRICE_INVALID = "29";
    // 'call buy contract fail'
    string public constant LPD_ROUNDS_CALL_BUY_CONTRACT_FAILED = "30";
    // 'call open contract fail'
    string public constant LPD_ROUNDS_CALL_OPEN_CONTRACT_FAILED = "31";
    // "erc20 balance not enough"
    string public constant LPD_ROUNDS_ERC20_BLC_NOT_ENOUGH = "32";
    // "eth send value not enough"
    string public constant LPD_ROUNDS_PAY_VALUE_NOT_ENOUGH = "33";
    // 'eth send value not need'
    string public constant LPD_ROUNDS_PAY_VALUE_NOT_NEED = "34";
    // 'eth send value upper need value'
    string public constant LPD_ROUNDS_PAY_VALUE_UPPER_NEED = "35";
    // 'not found abi to encode'
    string public constant LPD_ROUNDS_ABI_NOT_FOUND = "36";
    // 'sale end'
    string public constant LPD_ROUNDS_SALE_END = "37";
    // 'sale end time invalid'
    string public constant LPD_ROUNDS_SALE_END_TIME_INVALID = "38";
    // 'whitelist buy number limit'
    string public constant LPD_ROUNDS_WHITELIST_BUY_NUM_LIMIT = "39";
    // 'whitelist sale not start yet'
    string public constant LPD_ROUNDS_WHITELIST_SALE_NOT_START = "40";
    // 'rounds have no'
    string public constant LPD_ROUNDS_HAVE_NO = "41";
    // 'perIdQuantity invalid'
    string public constant LPD_ROUNDS_PER_ID_QUANTITY_INVALID = "42";
}