// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9;

import './SwapBase.sol';

contract BridgeSwap is SwapBase {

    function bridgeWithSwapNative(
        address _receiver,
        uint256 _amountIn,
        uint64 _dstChainId,
        address _srcBridgeToken,
        SwapInfoDest calldata _dstSwap,
        uint32 _maxBridgeSlippage
    ) external payable {
        uint256 _fee = _deriveFeeAndPerformChecksNative(_amountIn, _dstChainId, _dstSwap.integrator, _srcBridgeToken);

        _sendBridgeMessage(_receiver, _dstChainId, _srcBridgeToken, _dstSwap, _maxBridgeSlippage, _fee, _amountIn);
    }

    function bridgeWithSwap(
        address _receiver,
        uint256 _amountIn,
        uint64 _dstChainId,
        address _srcBridgeToken,
        SwapInfoDest calldata _dstSwap,
        uint32 _maxBridgeSlippage
    ) external payable {
        uint256 _fee = _deriveFeeAndPerformChecks(_amountIn, _dstChainId, _dstSwap.integrator, _srcBridgeToken);

        _sendBridgeMessage(_receiver, _dstChainId, _srcBridgeToken, _dstSwap, _maxBridgeSlippage, _fee, _amountIn);
    }

    function _sendBridgeMessage(
        address _receiver,
        uint64 _dstChainId,
        address _srcBridgeToken,
        SwapInfoDest calldata _dstSwap,
        uint32 _maxBridgeSlippage,
        uint256 _fee,
        uint256 _amountIn
    ) private {
        BaseCrossChainParams memory _baseParams = BaseCrossChainParams(
            _srcBridgeToken,
            _amountIn,
            _dstChainId,
            _retrieveDstTokenAddress(_dstSwap),
            _dstSwap.amountOutMinimum,
            _dstSwap.receiverEOA,
            _dstSwap.integrator,
            address(0)
        );

        require(_baseParams.dstChainID != uint64(block.chainid), 'same chain id');

        bytes32 id = _sendMessage(
            _receiver,
            uint64(_baseParams.dstChainID),
            _dstSwap,
            _maxBridgeSlippage,
            _beforeSwapAndSendMessage(),
            _fee,
            _baseParams.srcInputToken,
            _baseParams.srcInputAmount,
            true
        );

        emit CrossChainRequestSent(id, _baseParams);
    }
}