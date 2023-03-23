// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

library Errors {
    string public constant CP_CALLER_IS_NOT_FACTORY_OWNER = "1";
    string public constant CP_GAP_OR_DURATION_OUT_OF_INDEX = "2";
    string public constant CP_NFT_ON_MARKET_OR_UNAVAILABLE = "3";
    string public constant CP_NOT_THE_OWNER = "4";

    string public constant CP_INVALID_AMOUNT = "5";
    string public constant CP_INVALID_RECEIVER = "6";
    string public constant CP_NOT_ENOUGH_BALANCE = "7";

    string public constant CP_CAN_NOT_OPEN_CALL = "8";
    string public constant CP_DID_NOT_SEND_ENOUGH_ETH = "9";

    string public constant CP_ARRAY_LENGTH_UNMATCHED = "10";

    string public constant CP_NOT_IN_THE_EXERCISE_PERIOD = "11";

    string public constant CP_STRIKE_GAP_TOO_LOW = "12";
    string public constant CP_DURATION_TOO_LONG = "13";
    string public constant CP_STRIKE_PRICE_TOO_LOW = "14";

    string public constant CP_TOO_LITTLE_PREMIUM_TO_OWNER = "15";
    string public constant CP_PREMIUM_AND_ETH_UNEQUAL = "16";
    string public constant CP_CAN_NOT_OPEN_A_POSITION_ON_SELF_OWNED_NFT = "17";

    string public constant CP_DEACTIVATED = "18";
    string public constant CP_ACTIVATED = "19";

    string public constant CP_PRICE_TOO_HIGH = "20";

    string public constant CP_ZERO_SIZED_ARRAY = "21";

    string public constant CP_UNABLE_TO_TRANSFER_ETH = "22";

    string public constant CP_NOT_ENOUGH_OR_TOO_MUCH_ETH = "23";
}

library ErrorCodes {
    uint256 public constant CP_CALLER_IS_NOT_FACTORY_OWNER = 1;
    uint256 public constant CP_GAP_OR_DURATION_OUT_OF_INDEX = 2;
    uint256 public constant CP_NFT_ON_MARKET_OR_UNAVAILABLE = 3;
    uint256 public constant CP_NOT_THE_OWNER = 4;

    uint256 public constant CP_INVALID_AMOUNT = 5;
    uint256 public constant CP_INVALID_RECEIVER = 6;
    uint256 public constant CP_NOT_ENOUGH_BALANCE = 7;

    uint256 public constant CP_CAN_NOT_OPEN_CALL = 8;
    uint256 public constant CP_DID_NOT_SEND_ENOUGH_ETH = 9;

    uint256 public constant CP_ARRAY_LENGTH_UNMATCHED = 10;

    uint256 public constant CP_NOT_IN_THE_EXERCISE_PERIOD = 11;

    uint256 public constant CP_STRIKE_GAP_TOO_LOW = 12;
    uint256 public constant CP_DURATION_TOO_LONG = 13;
    uint256 public constant CP_STRIKE_PRICE_TOO_LOW = 14;

    uint256 public constant CP_TOO_LITTLE_PREMIUM_TO_OWNER = 15;
    uint256 public constant CP_PREMIUM_AND_ETH_UNEQUAL = 16;
    uint256 public constant CP_CAN_NOT_OPEN_A_POSITION_ON_SELF_OWNED_NFT = 17;

    uint256 public constant CP_DEACTIVATED = 18;
    uint256 public constant CP_ACTIVATED = 19;

    uint256 public constant CP_PRICE_TOO_HIGH = 20;

    uint256 public constant CP_ZERO_SIZED_ARRAY = 21;

    uint256 public constant CP_UNABLE_TO_TRANSFER_ETH = 22;
    
    uint256 public constant CP_NOT_ENOUGH_OR_TOO_MUCH_ETH = 23;
}