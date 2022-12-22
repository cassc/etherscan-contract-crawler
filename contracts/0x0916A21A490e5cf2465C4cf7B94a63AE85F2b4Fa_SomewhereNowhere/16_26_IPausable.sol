// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IPausable {
    error IsNotPaused();

    error IsPaused();

    event Paused(address indexed senderAddress);

    event Unpaused(address indexed senderAddress);

    function isPaused() external view returns (bool);
}