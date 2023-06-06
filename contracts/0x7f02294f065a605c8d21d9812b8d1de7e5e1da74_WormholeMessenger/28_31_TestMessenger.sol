// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IMessenger} from "../interfaces/IMessenger.sol";

contract TestMessenger is IMessenger {
    bool public isHasMessage = false;

    event Sent();

    function sentMessagesBlock(bytes32) external view override returns (uint) {
        return isHasMessage ? 1 : 0;
    }

    function receivedMessages(bytes32) external view override returns (uint) {
        return isHasMessage ? 1 : 0;
    }

    function sendMessage(bytes32) external payable override {
        emit Sent();
    }

    function receiveMessage(
        bytes32 message,
        uint v1v2,
        bytes32 r1,
        bytes32 s1,
        bytes32 r2,
        bytes32 s2
    ) external override {
        // Do nothing
    }

    function getTransactionCost(uint) external pure returns (uint) {
        return 1000;
    }

    function setIsHasMessage(bool isHasMessage_) external {
        isHasMessage = isHasMessage_;
    }
}