// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.14;

struct LiqRequest {
    uint8 bridgeId;
    bytes txData;
    address token;
    address allowanceTarget; /// @dev should check with socket.
    uint256 amount;
    uint256 nativeAmount;
}

struct BridgeRequest {
    uint256 id;
    uint256 optionalNativeAmount;
    address inputToken;
    bytes data;
}

struct MiddlewareRequest {
    uint256 id;
    uint256 optionalNativeAmount;
    address inputToken;
    bytes data;
}

struct UserRequest {
    address receiverAddress;
    uint256 toChainId;
    uint256 amount;
    MiddlewareRequest middlewareRequest;
    BridgeRequest bridgeRequest;
}

struct LiqStruct {
    address inputToken;
    address bridge;
    UserRequest socketInfo;
}

//["0x092A9faFA20bdfa4b2EE721FE66Af64d94BB9FAF","1","3000000",["0","0","0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174","0x"],["7","0","0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174","0x00000000000000000000000076b22b8c1079a44f1211d867d68b1eda76a635a7000000000000000000000000000000000000000000000000000000000003db5400000000000000000000000000000000000000000000000000000000002a3a8f0000000000000000000000000000000000000000000000000000017fc2482f6800000000000000000000000000000000000000000000000000000000002a3a8f0000000000000000000000000000000000000000000000000000017fc2482f680000000000000000000000002791bca1f2de4661ed88a30c99a7a9449aa84174"]]