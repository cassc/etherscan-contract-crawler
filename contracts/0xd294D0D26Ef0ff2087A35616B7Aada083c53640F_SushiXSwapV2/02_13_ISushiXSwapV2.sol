// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.10;

import "./IRouteProcessor.sol";
import "./ISushiXSwapV2Adapter.sol";
import "./IWETH.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/contracts/utils/Multicall.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

interface ISushiXSwapV2 {
    struct BridgeParams {
        bytes2 refId;
        address adapter;
        address tokenIn;
        uint256 amountIn;
        address to;
        bytes adapterData;
    }

    /// @notice Emitted when a bridge or swapAndBridge is executed
    /// @param refId The reference id for integrators to pass when using xswap
    /// @param sender The address of the sender
    /// @param adapter The address of the adapter to bridge through
    /// @param tokenIn The address of the token to bridge or pre-bridge swap from
    /// @param amountIn The amount of token to bridge or pre-bridge swap from
    /// @param to The address to send the bridged or post-bridge swapped token to 
    event SushiXSwapOnSrc(
        bytes2 indexed refId,
        address indexed sender,
        address adapter,
        address tokenIn,
        uint256 amountIn,
        address to
    );

    /// @notice Update Adapter status to enable or disable for use
    /// @param _adapter The address of the adapter to update
    /// @param _status The status to set the adapter to
    function updateAdapterStatus(address _adapter, bool _status) external;
    
    /// @notice Update the RouteProcessor contract that is used
    /// @param newRouteProcessor The address of the new RouteProcessor contract
    function updateRouteProcessor(address newRouteProcessor) external;

    /// @notice Execute a swap using _swapData with RouteProcessor
    /// @param _swapData The data to pass to RouteProcessor
    function swap(bytes memory _swapData) external payable;

    /// @notice Perform a bridge through passed adapter in _bridgeParams
    /// @param _bridgeParams The bridge data for the function call
    /// @param _refundAddress The address to refund excess funds to
    /// @param _swapPayload The swap data payload to pass to adapter
    /// @param _payloadData The payload data to pass to adapter
    function bridge(
        BridgeParams calldata _bridgeParams,
        address _refundAddress,
        bytes calldata _swapPayload,
        bytes calldata _payloadData
    ) external payable;
    
    /// @notice Perform a swap then bridge through passed adapter in _bridgeParams
    /// @param _bridgeParams The bridge data for the function call
    /// @param _refundAddress The address to refund excess funds to
    /// @param _swapData The swap data to pass to RouteProcessor
    /// @param _swapPayload The swap data payload to pass to adapter
    /// @param _payloadData The payload data to pass to adapter
    function swapAndBridge(
        BridgeParams calldata _bridgeParams,
        address _refundAddress,
        bytes calldata _swapData,
        bytes calldata _swapPayload,
        bytes calldata _payloadData
    ) external payable;
    
    /// @notice Send a message through passed _adapter address
    /// @param _adapter The address of the adapter to send the message through
    /// @param _adapterData The data to pass to the adapter
    function sendMessage(
        address _adapter,
        bytes calldata _adapterData
    ) external payable;
}