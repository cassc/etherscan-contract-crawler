// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IMessage {
    function nonces(address account, uint256 pid) external returns (uint64);

    function messageBus() external returns (address);
}