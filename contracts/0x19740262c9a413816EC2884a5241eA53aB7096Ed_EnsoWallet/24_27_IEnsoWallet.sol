// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IEnsoWallet {
    function initialize(
        address owner,
        bytes32 salt,
        bytes32 shortcutId,
        bytes32[] calldata commands,
        bytes[] calldata state
    ) external payable;
}