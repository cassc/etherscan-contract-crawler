// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ICentralBroCommittee {
    function getReceivedBlock(address account) external view returns(uint256);
}