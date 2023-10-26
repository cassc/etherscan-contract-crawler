// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./DefaultCallbackHandler.sol";

contract EthscriptionsFallbackHandler is DefaultCallbackHandler {
    fallback() external {
        // Ensure the call data is at least 20 bytes long to hold the appended msg.sender
        require(msg.data.length >= 20, "Call data too short");
        // Remove the last 20 bytes (appended msg.sender) from the length before checking
        uint256 adjustedLength = msg.data.length - 20;
        // Now check that the adjusted length is a multiple of 32 bytes
        require(adjustedLength % 32 == 0, "Invalid concatenated hashes length");
    }
}