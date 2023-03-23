// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract HopL1BridgeMock {
    address public immutable l1CanonicalToken;

    constructor(address token) {
        l1CanonicalToken = token;
    }
}