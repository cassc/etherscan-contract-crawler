// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IZKBridgeReceiver {
    // @notice ZKBridge endpoint will invoke this function to deliver the message on the destination
    // @param srcChainId - the source endpoint identifier
    // @param srcAddress - the source sending contract address from the source chain
    // @param sequence - the ordered message nonce
    // @param payload - the signed payload is the UA bytes has encoded to be sent
    function zkReceive(uint16 srcChainId, address srcAddress, uint64 sequence, bytes calldata payload) external;
}