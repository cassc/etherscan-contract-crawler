// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8;

interface ICelerMessageBus {
    function sendMessage(
        address receiver,
        uint256 dstChainId,
        bytes calldata message
    ) external payable;

    function calcFee(bytes calldata message) external view returns (uint256);
}