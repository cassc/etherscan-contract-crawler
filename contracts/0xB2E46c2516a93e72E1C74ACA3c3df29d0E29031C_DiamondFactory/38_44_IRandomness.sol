//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

struct RandomnessContract {
    bytes32[] randomSalts;
    uint8 _saltIndex;
    bool _initialized;
}