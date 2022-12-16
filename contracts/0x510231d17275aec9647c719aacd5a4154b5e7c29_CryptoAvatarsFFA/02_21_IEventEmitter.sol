// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IEventEmitter {
    function emitEvent(string memory eventName, bytes calldata eventData)
        external
        returns (bool);
}