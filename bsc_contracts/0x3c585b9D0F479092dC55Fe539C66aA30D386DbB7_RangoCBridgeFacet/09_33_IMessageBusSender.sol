// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

interface IMessageBusSender {
    function calcFee(bytes calldata _message) external view returns (uint256);
}