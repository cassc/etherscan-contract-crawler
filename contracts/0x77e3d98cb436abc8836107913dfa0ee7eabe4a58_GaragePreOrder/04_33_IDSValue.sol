// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.13;

interface IDSValue {
    function peek() external view returns (bytes32, bool);

    function read() external view returns (bytes32);

    function poke(bytes32 wut) external;

    function void() external;
}