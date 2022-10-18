// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

interface IFactory {
    function create(bytes calldata args) external returns (address instance);

    function create2(bytes calldata args, bytes32 salt) external returns (address instance);
}