// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

interface IPermit {
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}