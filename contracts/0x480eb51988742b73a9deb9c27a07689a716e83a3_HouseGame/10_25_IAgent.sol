// SPDX-License-Identifier: MIT LICENSE 

pragma solidity ^0.8.4;

interface IAgent {
    function addManyToAgentAndPack(address account, uint16[] calldata tokenIds) external;
}