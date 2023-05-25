// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @title IGatewayClient
 * @notice Cross-chain gateway client interface
 */
interface IGatewayClient {
    /**
     * @notice Cross-chain message handler on the target chain
     * @dev The function is called by cross-chain gateways
     * @param _messageSourceChainId The ID of the message source chain
     * @param _payloadData The content of the cross-chain message
     */
    function handleExecutionPayload(
        uint256 _messageSourceChainId,
        bytes calldata _payloadData
    ) external;

    /**
     * @notice The standard "receive" function
     */
    receive() external payable;
}