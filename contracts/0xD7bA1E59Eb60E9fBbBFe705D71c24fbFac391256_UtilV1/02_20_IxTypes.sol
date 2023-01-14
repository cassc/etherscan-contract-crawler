//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IxTypes {
    struct PermitData {
        address owner;
        address spender;
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
}