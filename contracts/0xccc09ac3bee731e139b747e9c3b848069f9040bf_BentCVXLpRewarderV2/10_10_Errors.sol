// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

library Errors {
    string public constant ZERO_ADDRESS = "100";
    string public constant ZERO_AMOUNT = "101";
    string public constant INVALID_ADDRESS = "102";
    string public constant INVALID_AMOUNT = "103";
    string public constant NO_PENDING_REWARD = "104";
    string public constant INVALID_PID = "105";
    string public constant INVALID_POOL_ADDRESS = "106";
    string public constant UNAUTHORIZED = "107";
    string public constant ALREADY_EXISTS = "108";
    string public constant SAME_ALLOCPOINT = "109";
    string public constant INVALID_REWARD_PER_BLOCK = "110";
    string public constant INSUFFICIENT_REWARDS = "111";
    string public constant EXCEED_MAX_HARVESTER_FEE = "112";
    string public constant EXCEED_MAX_FEE = "113";
    string public constant INVALID_INDEX = "114";
    string public constant INVALID_REQUEST = "115";
    string public constant INVALID_WINDOW_LENGTH = "116";
}