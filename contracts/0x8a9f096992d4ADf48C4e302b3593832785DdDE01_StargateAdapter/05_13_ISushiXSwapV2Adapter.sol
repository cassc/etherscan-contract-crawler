// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.10;

import "./IPayloadExecutor.sol";

interface ISushiXSwapV2Adapter {
    
    /// @dev Most adapters will implement their own struct for the adapter, but this can be used for generic adapters
    struct BridgeParamsAdapter {
        address tokenIn;
        uint256 amountIn;
        address to;
        bytes adapterData;
    }

    struct PayloadData {
        address target;
        uint256 gasLimit;
        bytes targetData;
    }
    
    /// @notice Perform a swap after post bridging
    /// @param _amountBridged The amount of tokens bridged
    /// @param _swapData The swap data to pass to RouteProcessor
    /// @param _token The address of the token to swap
    /// @param _payloadData The payload data to pass to payload executor
    function swap(
        uint256 _amountBridged,
        bytes calldata _swapData,
        address _token,
        bytes calldata _payloadData
    ) external payable;

    /// @notice Execute a payload after bridging - w/o pre-swapping
    /// @param _amountBridged The amount of tokens bridged
    /// @param _payloadData The payload data to pass to payload executor
    /// @param _token The address of the token to swap
    function executePayload(
        uint256 _amountBridged,
        bytes calldata _payloadData,
        address _token
    ) external payable;

    /// @notice Where the actual bridging is executed from on adapter
    /// @param _adapterData The adapter data to pass to adapter
    /// @param _swapDataPayload The swap data payload to pass through bridge
    /// @param _payloadData The payload data to pass to pass through bridge
    function adapterBridge(
        bytes calldata _adapterData,
        address _refundAddress,
        bytes calldata _swapDataPayload,
        bytes calldata _payloadData
    ) external payable;
    
    /// @notice Where the actual messaging is executed from on adapter
    /// @param _adapterData The adapter data to pass to adapter
    function sendMessage(bytes calldata _adapterData) external;
}