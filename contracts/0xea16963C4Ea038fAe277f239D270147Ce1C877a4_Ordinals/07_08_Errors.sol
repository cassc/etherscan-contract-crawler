// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

library Errors {
    enum ReturnCode {
        SUCCESS,
        FAILED
    }

    string public constant SUCCESS = "0";

    address public constant ZERO_ADDR = address(0x0);

    // common errors
    string public constant INV_ADD = "100";
    string public constant ONLY_ADMIN_ALLOWED = "101";
    string public constant ONLY_CREATOR = "102";

    // validation error
    string public constant MISSING_NAME = "200";
    string public constant INV_FEE_PROJECT = "201";
    string public constant INV_PROJECT = "202";
    string public constant REACH_MAX = "203";
    string public constant INV_PARAMS = "204";
    string public constant TOO_HIGH = "205";
    string public constant TOKEN_HAS_SEED = "206";
    string public constant ZERO_SEED = "207";
    string public constant OPENING_SCHEDULE = "208";
    string public constant INV_TOKEN = "209";
    string public constant FORBIDDEN_TRANSFER_PROJECT = "210";

    // validator market error
    string public constant INVALID_ERC721_OWNER = "300";
    string public constant ERC_721_NOT_APPROVED = "301";
    string public constant OFFERING_CLOSED = "302";
    string public constant VALUE_INVALID = "303";
    string public constant ERC20_BALANCE_INVALID = "304";
    string public constant ERC20_NOT_APPROVED = "305";
    string public constant TRANSFER_FAIL = "306";
    string public constant ERC_20_NOT_ALLOW = "307";
    string public constant ZERO_PRICE = "308";
    string public constant ZERO_DURATION = "309";

    // GEN Token
    string public constant POA_INVALID_TOKEN = "400";
    string public constant TEAM_VESTING_ERROR_ADDR = "401";
    string public constant DAO_VESTING_ERROR_ADDR = "402";
    string public constant VESTING_TIME_LOCK = "403";
    string public constant VESTING_REMAIN = "404";
}