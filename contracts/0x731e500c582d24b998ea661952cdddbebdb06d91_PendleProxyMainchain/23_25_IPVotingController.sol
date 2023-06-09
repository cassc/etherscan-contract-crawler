// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPVotingController {
    function vote(address[] calldata pools, uint64[] calldata weights) external;
}