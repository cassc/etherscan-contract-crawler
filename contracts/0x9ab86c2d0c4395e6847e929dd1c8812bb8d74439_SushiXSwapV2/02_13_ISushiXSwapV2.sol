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

    event SushiXSwapOnSrc(
        bytes2 indexed refId,
        address indexed sender,
        address adapter,
        address tokenIn,
        uint256 amountIn,
        address to
    );

    function updateAdapterStatus(address _adapter, bool _status) external;

    function updateRouteProcessor(address newRouteProcessor) external;

    function swap(bytes memory _swapData) external payable;

    function bridge(
        BridgeParams calldata _bridgeParams,
        bytes calldata _swapPayload,
        bytes calldata _payloadData
    ) external payable;

    function swapAndBridge(
        BridgeParams calldata _bridgeParams,
        bytes calldata _swapData,
        bytes calldata _swapPayload,
        bytes calldata _payloadData
    ) external payable;

    function sendMessage(
        address _adapter,
        bytes calldata _adapterData
    ) external payable;
}