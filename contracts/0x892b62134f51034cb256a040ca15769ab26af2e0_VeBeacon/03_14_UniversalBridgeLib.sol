// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.4;

import "./bridges/ArbitrumBridge.sol";
import "./bridges/OptimismBridge.sol";
import "./bridges/PolygonBridge.sol";
import "./bridges/ArbitraryMessageBridge.sol";

/// @title Unified library for sending messages from Ethereum to other chains and rollups
/// @author zefram.eth
/// @notice Enables sending messages from Ethereum to other chains via a single interface.
library UniversalBridgeLib {
    /// -----------------------------------------------------------------------
    /// Constants
    /// -----------------------------------------------------------------------

    uint256 internal constant DEFAULT_MAX_FEE_PER_GAS = 0.1 gwei;

    uint256 internal constant CHAINID_ARBITRUM = 42161;
    ArbitrumBridge internal constant BRIDGE_ARBITRUM = ArbitrumBridge(0x4Dbd4fc535Ac27206064B68FfCf827b0A60BAB3f);

    uint256 internal constant CHAINID_OPTIMISM = 10;
    OptimismBridge internal constant BRIDGE_OPTIMISM = OptimismBridge(0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1);

    uint256 internal constant CHAINID_POLYGON = 137;
    PolygonBridge internal constant BRIDGE_POLYGON = PolygonBridge(0xfe5e5D361b2ad62c541bAb87C45a0B9B018389a2);

    uint256 internal constant CHAINID_BSC = 56;
    ArbitraryMessageBridge internal constant BRIDGE_BSC =
        ArbitraryMessageBridge(0x07955be2967B655Cf52751fCE7ccC8c61EA594e2);

    uint256 internal constant CHAINID_GNOSIS = 100;
    ArbitraryMessageBridge internal constant BRIDGE_GNOSIS =
        ArbitraryMessageBridge(0x4C36d2919e407f0Cc2Ee3c993ccF8ac26d9CE64e);

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error UniversalBridgeLib__GasLimitTooLarge();
    error UniversalBridgeLib__ChainIdNotSupported();
    error UniversalBridgeLib__MsgValueNotSupported();

    /// -----------------------------------------------------------------------
    /// Main functions
    /// -----------------------------------------------------------------------

    /// @notice Sends message to recipient on target chain with the given calldata.
    /// @dev For calls to Arbitrum, any extra msg.value above what getRequiredMessageValue() returns will
    /// be used as the msg.value of the L2 call to the recipient.
    /// @param chainId the target chain's ID
    /// @param recipient the message recipient on the target chain
    /// @param data the calldata the recipient will be called with
    /// @param gasLimit the gas limit of the call to the recipient
    /// @param value the amount of ETH to send along with the message (only supported by Arbitrum)
    function sendMessage(uint256 chainId, address recipient, bytes memory data, uint256 gasLimit, uint256 value)
        internal
    {
        sendMessage(chainId, recipient, data, gasLimit, value, DEFAULT_MAX_FEE_PER_GAS);
    }

    /// @notice Sends message to recipient on target chain with the given calldata.
    /// @dev For calls to Arbitrum, any extra msg.value above what getRequiredMessageValue() returns will
    /// be used as the msg.value of the L2 call to the recipient.
    /// @param chainId the target chain's ID
    /// @param recipient the message recipient on the target chain
    /// @param data the calldata the recipient will be called with
    /// @param gasLimit the gas limit of the call to the recipient
    /// @param value the amount of ETH to send along with the message (only supported by Arbitrum)
    /// @param maxFeePerGas the max gas price used, only relevant for some chains (e.g. Arbitrum)
    function sendMessage(
        uint256 chainId,
        address recipient,
        bytes memory data,
        uint256 gasLimit,
        uint256 value,
        uint256 maxFeePerGas
    ) internal {
        if (chainId == CHAINID_ARBITRUM) _sendMessageArbitrum(recipient, data, gasLimit, value, maxFeePerGas);
        else if (chainId == CHAINID_OPTIMISM) _sendMessageOptimism(recipient, data, gasLimit, value);
        else if (chainId == CHAINID_POLYGON) _sendMessagePolygon(recipient, data, value);
        else if (chainId == CHAINID_BSC) _sendMessageAMB(BRIDGE_BSC, recipient, data, gasLimit, value);
        else if (chainId == CHAINID_GNOSIS) _sendMessageAMB(BRIDGE_GNOSIS, recipient, data, gasLimit, value);
        else revert UniversalBridgeLib__ChainIdNotSupported();
    }

    /// @notice Computes the minimum msg.value needed when calling sendMessage()
    /// @param chainId the target chain's ID
    /// @param dataLength the length of the calldata the recipient will be called with, in bytes
    /// @param gasLimit the gas limit of the call to the recipient
    /// @return the minimum msg.value required
    function getRequiredMessageValue(uint256 chainId, uint256 dataLength, uint256 gasLimit)
        internal
        view
        returns (uint256)
    {
        return getRequiredMessageValue(chainId, dataLength, gasLimit, DEFAULT_MAX_FEE_PER_GAS);
    }

    /// @notice Computes the minimum msg.value needed when calling sendMessage()
    /// @param chainId the target chain's ID
    /// @param dataLength the length of the calldata the recipient will be called with, in bytes
    /// @param gasLimit the gas limit of the call to the recipient
    /// @param maxFeePerGas the max gas price used, only relevant for some chains (e.g. Arbitrum)
    /// @return the minimum msg.value required
    function getRequiredMessageValue(uint256 chainId, uint256 dataLength, uint256 gasLimit, uint256 maxFeePerGas)
        internal
        view
        returns (uint256)
    {
        if (chainId != CHAINID_ARBITRUM) {
            return 0;
        } else {
            uint256 submissionCost = BRIDGE_ARBITRUM.calculateRetryableSubmissionFee(dataLength, block.basefee);
            return gasLimit * maxFeePerGas + submissionCost;
        }
    }

    /// -----------------------------------------------------------------------
    /// Internal helpers for sending message to different chains
    /// -----------------------------------------------------------------------

    function _sendMessageArbitrum(
        address recipient,
        bytes memory data,
        uint256 gasLimit,
        uint256 value,
        uint256 maxFeePerGas
    ) internal {
        uint256 submissionCost = BRIDGE_ARBITRUM.calculateRetryableSubmissionFee(data.length, block.basefee);
        uint256 l2CallValue = value - submissionCost - gasLimit * maxFeePerGas;
        BRIDGE_ARBITRUM.createRetryableTicket{value: value}(
            recipient, l2CallValue, submissionCost, msg.sender, msg.sender, gasLimit, maxFeePerGas, data
        );
    }

    function _sendMessageOptimism(address recipient, bytes memory data, uint256 gasLimit, uint256 value) internal {
        if (value != 0) revert UniversalBridgeLib__MsgValueNotSupported();
        if (gasLimit > type(uint32).max) revert UniversalBridgeLib__GasLimitTooLarge();
        BRIDGE_OPTIMISM.sendMessage(recipient, data, uint32(gasLimit));
    }

    function _sendMessagePolygon(address recipient, bytes memory data, uint256 value) internal {
        if (value != 0) revert UniversalBridgeLib__MsgValueNotSupported();
        BRIDGE_POLYGON.sendMessageToChild(recipient, data);
    }

    function _sendMessageAMB(
        ArbitraryMessageBridge bridge,
        address recipient,
        bytes memory data,
        uint256 gasLimit,
        uint256 value
    ) internal {
        if (value != 0) revert UniversalBridgeLib__MsgValueNotSupported();
        if (gasLimit > bridge.maxGasPerTx()) revert UniversalBridgeLib__GasLimitTooLarge();
        bridge.requireToPassMessage(recipient, data, gasLimit);
    }
}