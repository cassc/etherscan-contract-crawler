// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

contract wBTCzConstants {
    
    uint256 constant MAX_ADMIN_NUMBER   = 50;
    uint8 constant ACTION_NUMBER        = 10;
    uint8 constant ACTION_VALUE_TYPE    = 3;
    uint256 constant ADMIN_GROUP        = 0;
    uint8[ACTION_NUMBER] INITIAL_PCTS = [60,60,60,60,60,40,40,80,80,100];
    
    enum Action {
        ADD_ADMIN,
        REMOVE_ADMIN,
        MINTING_ADDRESS,
        PAUSE_TOKEN,
        UNPAUSE_TOKEN,
        MINT_TOKEN,
        BURN_TOKEN,
        CHANGE_ADMIN_PCT,
        CHANGE_TOKEN_PCT,
        MANAGEMENT_PCT
    }
    string[ACTION_NUMBER] ActionString=[
        "ADD_ADMIN",
        "REMOVE_ADMIN",
        "MINTING_ADDRESS",
        "PAUSE_TOKEN",
        "UNPAUSE_TOKEN",
        "MINT_TOKEN",
        "BURN_TOKEN",
        "CHANGE_ADMIN_PCT",
        "CHANGE_TOKEN_PCT",
        "MANAGEMENT_PCT"
    ];
    enum ActionValueType {
        PCT,
        AMOUNT,
        ADDRESS
    }
    string[ACTION_VALUE_TYPE] ActionValueTypeString=[
        "PCT: 1 to 100",
        "AMOUNT",
        "ADDRESS"
    ];
    string[3] ResultString=[
        "DENIED",
        "ACTIVE",
        "APPROVED"
    ];
    constructor(){}
}