// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IIFBridgableStakeWeight {
    enum BridgeType {
        UserWeight,
        TotalWeight
    }

    struct MessageRequest {
        // user address
        address[] users;
        // timestamp value
        uint80 timestamp;
        // bridge type
        BridgeType bridgeType;
        // track number
        uint24 trackId;
        // amount of weight at timestamp
        uint192[] weights;
    }
}