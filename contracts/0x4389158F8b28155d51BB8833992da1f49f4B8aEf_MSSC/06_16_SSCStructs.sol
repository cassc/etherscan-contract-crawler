// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "./SSCEnums.sol";

struct Instruction {
    bytes32 id;
    address receiver;
    address asset;
    uint256 amount;
}

struct SettlementCycle {
    bytes32[] instructions;
    bool executed;
}

struct DepositItem {
    DepositType depositType;
    bytes32 instructionId;
    address token;
}