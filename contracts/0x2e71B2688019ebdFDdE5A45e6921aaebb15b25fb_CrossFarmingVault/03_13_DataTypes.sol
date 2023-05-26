// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library DataTypes {
    enum MessageTypes {
        Deposit,
        Withdraw,
        EmergencyWithdraw
    }

    struct CrossFarmRequest {
        address receiver;
        uint64 dstChainId;
        uint64 nonce;
        address account;
        uint256 pid;
        uint256 amount;
        MessageTypes msgType;
    }
}