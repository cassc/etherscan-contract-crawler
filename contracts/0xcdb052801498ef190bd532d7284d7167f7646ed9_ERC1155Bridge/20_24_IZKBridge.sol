// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IZKBridge {
    function send(
        uint16 dstChainId,
        address dstAddress,
        bytes calldata payload
    ) external payable returns (uint64 sequence);
}