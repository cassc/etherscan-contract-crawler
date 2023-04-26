// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

interface IMessageBus {
    function calcFee(bytes calldata _message) external view returns (uint256);
}