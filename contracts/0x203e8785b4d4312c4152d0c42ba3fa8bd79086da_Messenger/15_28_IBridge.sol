// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

enum MessengerProtocol {
    None,
    Allbridge,
    Wormhole,
    LayerZero
}

interface IBridge {
    function chainId() external view returns (uint);

    function processedMessages(bytes32) external view returns (uint);

    function sentMessages(bytes32) external view returns (uint);

    function otherBridges(uint) external view returns (bytes32);

    function otherBridgeTokens(uint, bytes32) external view returns (bool);

    function getBridgingCostInTokens(
        uint destinationChainId,
        MessengerProtocol messenger,
        address tokenAddress
    ) external view returns (uint);

    function hashMessage(
        uint amount,
        bytes32 recipient,
        uint sourceChainId,
        uint destinationChainId,
        bytes32 receiveToken,
        uint nonce,
        MessengerProtocol messenger
    ) external pure returns (bytes32);

    function receiveTokens(
        uint amount,
        bytes32 recipient,
        uint sourceChainId,
        bytes32 receiveToken,
        uint nonce,
        MessengerProtocol messenger,
        uint receiveAmountMin
    ) external payable;

    function withdrawGasTokens(uint amount) external;

    function registerBridge(uint chainId, bytes32 bridgeAddress) external;

    function addBridgeToken(uint chainId, bytes32 tokenAddress) external;

    function removeBridgeToken(uint chainId, bytes32 tokenAddress) external;

    function swapAndBridge(
        bytes32 token,
        uint amount,
        bytes32 recipient,
        uint destinationChainId,
        bytes32 receiveToken,
        uint nonce,
        MessengerProtocol messenger,
        uint feeTokenAmount
    ) external payable;
}