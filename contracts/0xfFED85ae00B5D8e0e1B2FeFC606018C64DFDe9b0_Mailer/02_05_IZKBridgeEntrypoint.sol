// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IZKBridgeEntrypoint {

    // @notice send a ZKBridge message to the specified address at a ZKBridge endpoint.
    // @param dstChainId - the destination chain identifier
    // @param dstAddress - the address on destination chain
    // @param payload - a custom bytes payload to send to the destination contract
    function send(uint16 dstChainId, address dstAddress, bytes memory payload) external payable returns (uint64 sequence);
}