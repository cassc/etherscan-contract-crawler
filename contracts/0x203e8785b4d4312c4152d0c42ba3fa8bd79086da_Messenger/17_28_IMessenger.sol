// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IMessenger {
    function sentMessagesBlock(bytes32 message) external view returns (uint);

    function receivedMessages(bytes32 message) external view returns (uint);

    function sendMessage(bytes32 message) external payable;

    function receiveMessage(bytes32 message, uint v1v2, bytes32 r1, bytes32 s1, bytes32 r2, bytes32 s2) external;
}