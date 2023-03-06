// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IStargateToken {
    event SendToChain(uint16 dstChainId, bytes to, uint256 qty);

    function isMain() external returns(bool);

    function sendTokens(
        uint16 _dstChainId, // send tokens to this chainId
        bytes calldata _to, // where to deliver the tokens on the destination chain
        uint256 _qty, // how many tokens to send
        address zroPaymentAddress, // ZRO payment address
        bytes calldata adapterParam // txParameters
    ) external payable;
}