// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library AliceNetFactoryBaseErrors {
    error Unauthorized();
    error CodeSizeZero();
    error SaltAlreadyInUse(bytes32 salt);
    error IncorrectProxyImplementation(address current, address expected);
}