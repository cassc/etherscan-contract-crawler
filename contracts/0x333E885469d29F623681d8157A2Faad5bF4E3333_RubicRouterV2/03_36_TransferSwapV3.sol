// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9;

import './SwapBase.sol';
import '../../interfaces/IUniswapRouterV3.sol';

contract TransferSwapV3 is SwapBase {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    function transferWithSwapV3Native(
        address _receiver,
        uint256 _amountIn,
        uint64 _dstChainId,
        SwapInfoV3 calldata _srcSwap,
        SwapInfoDest calldata _dstSwap,
        uint32 _maxBridgeSlippage
    ) external payable {
        uint256 _fee = _deriveFeeAndPerformChecksNative(_amountIn, _dstChainId, _dstSwap.integrator, address(_getFirstBytes20(_srcSwap.path)));

        _swapAndSendMessageV3(
            _receiver,
            _amountIn,
            _dstChainId,
            _srcSwap,
            _dstSwap,
            _maxBridgeSlippage,
            _fee,
            address(_getLastBytes20(_srcSwap.path))
        );
    }

    function transferWithSwapV3(
        address _receiver,
        uint256 _amountIn,
        uint64 _dstChainId,
        SwapInfoV3 calldata _srcSwap,
        SwapInfoDest calldata _dstSwap,
        uint32 _maxBridgeSlippage
    ) external payable {
        uint256 _fee = _deriveFeeAndPerformChecks(_amountIn, _dstChainId, _dstSwap.integrator, address(_getFirstBytes20(_srcSwap.path)));

        _swapAndSendMessageV3(
            _receiver,
            _amountIn,
            _dstChainId,
            _srcSwap,
            _dstSwap,
            _maxBridgeSlippage,
            _fee,
            address(_getLastBytes20(_srcSwap.path))
        );
    }

    /**
     * @notice Sends a cross-chain transfer via the liquidity pool-based bridge and sends a message specifying a wanted swap action on the
               destination chain via the message bus
     * @param _receiver the app contract that implements the MessageReceiver abstract contract
     *        NOTE not to be confused with the receiver field in SwapInfoV3 which is an EOA address of a user
     * @param _amountIn the input amount that the user wants to swap and/or bridge
     * @param _dstChainId destination chain ID
     * @param _srcSwap a struct containing swap related requirements
     * @param _dstSwap a struct containing swap related requirements
     * @param _maxBridgeSlippage the max acceptable slippage at bridge, given as percentage in point (pip). Eg. 5000 means 0.5%.
     *        Must be greater than minimalMaxSlippage. Receiver is guaranteed to receive at least (100% - max slippage percentage) * amount or the
     *        transfer can be refunded.
     * @param _fee the fee to pay to MessageBus.
     */
    function _swapAndSendMessageV3(
        address _receiver,
        uint256 _amountIn,
        uint64 _dstChainId,
        SwapInfoV3 calldata _srcSwap,
        SwapInfoDest calldata _dstSwap,
        uint32 _maxBridgeSlippage,
        uint256 _fee,
        address srcOutputToken
    ) private {
        BaseCrossChainParams memory _baseParams = BaseCrossChainParams(
            address(_getFirstBytes20(_srcSwap.path)),
            _amountIn,
            _dstChainId,
            _retrieveDstTokenAddress(_dstSwap),
            _dstSwap.amountOutMinimum,
            msg.sender,
            _dstSwap.integrator,
            _srcSwap.dex
        );

        require(_srcSwap.path.length > 20, 'empty swap path');

        (bool success, uint256 srcAmtOut) = _trySwapV3(_srcSwap, _amountIn);

        bytes32 id = _sendMessage(
            _receiver,
            uint64(_baseParams.dstChainID),
            _dstSwap,
            _maxBridgeSlippage,
            _beforeSwapAndSendMessage(), // TODO rename
            _fee,
            srcOutputToken,
            srcAmtOut,
            success
        );

        emit CrossChainRequestSent(id, _baseParams);
    }

    function _trySwapV3(SwapInfoV3 memory _swap, uint256 _amount) internal returns (bool ok, uint256 amountOut) {
        if (!availableRouters.contains(_swap.dex)) {
            return (false, 0);
        }

        SmartApprove.smartApprove(address(_getFirstBytes20(_swap.path)), _amount, _swap.dex);

        IUniswapRouterV3.ExactInputParams memory paramsV3 = IUniswapRouterV3.ExactInputParams(
            _swap.path,
            address(this),
            _swap.deadline,
            _amount,
            _swap.amountOutMinimum
        );

        try IUniswapRouterV3(_swap.dex).exactInput(paramsV3) returns (uint256 _amountOut) {
            return (true, _amountOut);
        } catch {
            return (false, 0);
        }
    }
}