// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.16;

import "./WormholeBridgeStructs.sol";

interface IWormholeTokenBridge {

    function attestToken(address tokenAddress, uint32 nonce) external payable returns (uint64 sequence);

    function wrapAndTransferETH(uint16 recipientChain, bytes32 recipient, uint256 arbiterFee, uint32 nonce) external payable returns (uint64 sequence);

    function wrapAndTransferETHWithPayload(uint16 recipientChain, bytes32 recipient, uint32 nonce, bytes memory payload) external payable returns (uint64 sequence);

    function transferTokens(address token, uint256 amount, uint16 recipientChain, bytes32 recipient, uint256 arbiterFee, uint32 nonce) external payable returns (uint64 sequence);

    function transferTokensWithPayload(address token, uint256 amount, uint16 recipientChain, bytes32 recipient, uint32 nonce, bytes memory payload) external payable returns (uint64 sequence);

    function updateWrapped(bytes memory encodedVm) external returns (address token);

    function createWrapped(bytes memory encodedVm) external returns (address token);

    function completeTransferWithPayload(bytes memory encodedVm) external returns (bytes memory);

    function completeTransferAndUnwrapETHWithPayload(bytes memory encodedVm) external returns (bytes memory);

    function completeTransfer(bytes memory encodedVm) external;

    function completeTransferAndUnwrapETH(bytes memory encodedVm) external;

    function encodeAssetMeta(WormholeBridgeStructs.AssetMeta memory meta) external pure returns (bytes memory encoded);

    function encodeTransfer(WormholeBridgeStructs.Transfer memory transfer) external pure returns (bytes memory encoded);

    function encodeTransferWithPayload(WormholeBridgeStructs.TransferWithPayload memory transfer) external pure returns (bytes memory encoded);

    function parsePayloadID(bytes memory encoded) external pure returns (uint8 payloadID);

    function parseAssetMeta(bytes memory encoded) external pure returns (WormholeBridgeStructs.AssetMeta memory meta);

    function parseTransfer(bytes memory encoded) external pure returns (WormholeBridgeStructs.Transfer memory transfer);

    function parseTransferWithPayload(bytes memory encoded) external pure returns (WormholeBridgeStructs.TransferWithPayload memory transfer);

    function isTransferCompleted(bytes32 hash) external view returns (bool);

    function wrappedAsset(uint16 tokenChainId, bytes32 tokenAddress) external view returns (address);

    function isWrappedAsset(address token) external view returns (bool);

    function outstandingBridged(address token) external view returns (uint256);

    function wormhole() external view returns (address);

    function chainId() external view returns (uint16);
}