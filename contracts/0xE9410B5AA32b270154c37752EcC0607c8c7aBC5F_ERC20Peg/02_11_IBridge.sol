// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

// Proof of a witnessed event by validators
struct EventProof {
    // The Id (nonce) of the event
    uint256 eventId;
    // The validator set Id which witnessed the event
    uint32 validatorSetId;
    // v,r,s are sparse arrays expected to align w public key in 'validators'
    // i.e. v[i], r[i], s[i] matches the i-th validator[i]
    // v part of validator signatures
    uint8[] v;
    // r part of validator signatures
    bytes32[] r;
    // s part of validator signatures
    bytes32[] s;
    // The validator addresses
    address[] validators;
}

interface IBridge {
    // A sent message event
    event SendMessage(uint messageId, address source, address destination, bytes message, uint256 fee);
    // Receive a bridge message from the remote chain
    function receiveMessage(address source, address destination, bytes calldata message, EventProof calldata proof) external payable;
    // Send a bridge message to the remote chain
    function sendMessage(address destination, bytes calldata message) external payable;
    // Send message fee - used by sendMessage caller to obtain required fee for sendMessage
    function sendMessageFee() external view returns (uint256);
}

interface IBridgeReceiver {
    // Handle a bridge message received from the remote chain
    // It is guaranteed to be valid
    function onMessageReceived(address source, bytes calldata message) external;
}