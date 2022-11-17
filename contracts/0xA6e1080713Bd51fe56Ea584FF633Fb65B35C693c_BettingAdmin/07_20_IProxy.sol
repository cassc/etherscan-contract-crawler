// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IProxy {
    function createClone(bytes32 salt) external returns (address);
}