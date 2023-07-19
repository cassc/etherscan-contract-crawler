// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

string constant CONTRACT_NAME = "GreyMarket Contract";
    
bytes32 constant CREATE_ORDER_TYPEHASH = 
    keccak256(
        "Create(bytes32 id,address buyer,address seller,address paymentToken,uint8 orderType,uint256 amount)"
    );

bytes32 constant CLAIM_ORDER_TYPEHASH = 
    keccak256(
        "Claim(bytes32 id,address seller,uint256 amount,address paymentToken,uint8 orderType)"
    );
    
bytes32 constant WITHDRAW_ORDER_TYPEHASH = 
    keccak256(
        "Withdraw(bytes32 id,address buyer,address seller,address paymentToken,uint256 amount)"
    );

struct Sig {
    uint8 v;
    bytes32 r;
    bytes32 s;
}

struct Order {
    bytes32 id;
    address seller;
    uint256 amount;
    address paymentToken;
    uint8 orderType;
}