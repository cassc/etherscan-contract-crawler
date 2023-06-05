// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract MembershipStorageV0 {
    // augment `tokenURI` through a Renderer contract
    address public renderer;
    // self-incrementing id for minting tokens, doubly functions as totalSupply function
    uint256 public totalSupply;
    // address of the payment collector, receieves all payments from minting events
    address public paymentCollector;
}