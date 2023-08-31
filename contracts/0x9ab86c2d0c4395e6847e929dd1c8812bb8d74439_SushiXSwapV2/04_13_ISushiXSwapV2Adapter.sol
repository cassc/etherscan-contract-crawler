// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.10;

import "./IPayloadExecutor.sol";

interface ISushiXSwapV2Adapter {
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

    function swap(
        uint256 _amountBridged,
        bytes calldata _swapData,
        address _token,
        bytes calldata _payloadData
    ) external payable;

    function adapterBridge(
        bytes calldata _adapterData,
        bytes calldata _swapDataPayload,
        bytes calldata _payloadData
    ) external payable;

    function sendMessage(bytes calldata _adapterData) external;
}