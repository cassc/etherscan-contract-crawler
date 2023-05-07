// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract SapienzStorageV1 {
    bytes32 public merkleRoot;

    // contracts allowed to claim sapienz mint spots
    mapping(address => bool) public allowedContracts;

    // contracts that do not require approvals
    mapping(address => bool) public controlledContracts;

    // mapping token address => token ID => claimant => claimed balance
    mapping(address => mapping(uint256 => mapping(address => uint256)))
        public claimedBalances;
}