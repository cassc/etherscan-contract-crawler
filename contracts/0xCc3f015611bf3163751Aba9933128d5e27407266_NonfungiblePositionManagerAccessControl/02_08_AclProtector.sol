// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

interface AclProtector {
    function check(bytes32 role, uint256 value, bytes calldata data) external returns (bool);
}