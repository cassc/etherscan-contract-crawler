// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;
pragma abicoder v2;

import './CallToken.sol';

contract CallTokenFactory {
    function deployCallToken(bytes32 salt) external returns (address callToken) {
        callToken = address(new CallToken{salt: salt}());
    }
}