// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library errors {
    string constant public NOT_AUTHORIZED = "001001";
    string constant public INVALID_ADDRESS = "001003";

    string constant public NOT_SINGLE_NFT = "002001";
    string constant public FRAME_ID_MISSING = "002002";

    string constant public ZERO_ADDRESS = "003001";
    string constant public NOT_VALID_NFT = "003002";
    string constant public NOT_OWNER_OR_OPERATOR = "003003";
    string constant public NOT_OWNER_APPROVED_OR_OPERATOR = "003004";
    string constant public NOT_ABLE_TO_RECEIVE_NFT = "003005";
    string constant public NFT_ALREADY_EXISTS = "003006";
    string constant public NOT_OWNER = "003007";
    string constant public IS_OWNER = "003008";

    string constant public FRAME_NOT_EMPTY = "004001";
    string constant public FRAME_EMPTY = "004002";

    string constant public NOT_VALID_MODEL = "005001";
    string constant public NOT_IN_STOCK = "005002";
    string constant public CHECK_NOT_VALID = "005003";
    string constant public INVALID_SIGNATURE = "005004";
}