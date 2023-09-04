// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IL2MessageSend {
    function sendMessage(uint16 _srcChainId, address _srcAddress, uint16 _dstChainId, address _dstAddress, uint64 _sequence, bytes calldata _payload) external payable;

    function getFee() external view returns (uint256 fee);
}