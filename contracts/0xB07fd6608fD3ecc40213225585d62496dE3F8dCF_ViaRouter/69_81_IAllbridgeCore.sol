// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IAllbridgeCore {
    function swapAndBridge(
        bytes32 token,
        uint256 amount,
        bytes32 recipient,
        uint8 destinationChainId,
        bytes32 receiveToken,
        uint256 nonce,
        uint8 messenger
    ) external payable;
}