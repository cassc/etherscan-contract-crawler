// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IZKBridgeEntrypoint {

    event MessagePublished(address indexed sender, uint16 indexed dstChainId, uint64 indexed sequence, address dstAddress, bytes payload);

    event ExecutedMessage(address indexed sender, uint16 indexed srcChainId, uint64 indexed sequence, address dstAddress, bytes payload);

    function send(uint16 dstChainId, address dstAddress, bytes memory payload) external payable returns (uint64 sequence);

    function validateTransactionProof(uint16 srcChainId, bytes32 srcBlockHash, uint256 logIndex, bytes memory mptProof) external;

    function sendFromL2(uint16 srcChainId, uint16 dstChainId, address dstAddress, bytes memory payload) external returns (uint64 sequence);

    function validateTransactionFromL2(uint16 srcChainId, address srcAddress, address dstAddress, uint64 sequence, bytes calldata payload) external;

}