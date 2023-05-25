// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IENSReverseRegistrar {
    function setName(string memory name) external returns (bytes32 node);
}