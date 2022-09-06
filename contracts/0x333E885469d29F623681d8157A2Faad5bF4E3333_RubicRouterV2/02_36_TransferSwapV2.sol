// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9;

import './SwapBase.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract TransferSwapV2 is SwapBase {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    function transferWithSwapV2Native(
        address _receiver,
        uint256 _amountIn,
        uint64 _dstChainId,
        SwapInfoV2 calldata _srcSwap,
        SwapInfoDest calldata _dstSwap,
        uint32 _maxBridgeSlippage
    ) external payable {
        uint256 _fee = _deriveFeeAndPerformChecksNative(_amountIn, _dstChainId, _dstSwap.integrator, _srcSwap.path[0]);

        _swapAndSendMessageV2(
            _receiver,
            _amountIn,
            _dstChainId,
            _srcSwap,
            _dstSwap,
            _maxBridgeSlippage,
            _fee,
            _srcSwap.path[_srcSwap.path.length - 1]
        );
    }

    function transferWithSwapV2(
        address _receiver,
        uint256 _amountIn,
        uint64 _dstChainId,
        SwapInfoV2 calldata _srcSwap,
        SwapInfoDest calldata _dstSwap,
        uint32 _maxBridgeSlippage
    ) external payable {
        uint256 _fee = _deriveFeeAndPerformChecks(_amountIn, _dstChainId, _dstSwap.integrator, _srcSwap.path[0]);

        _swapAndSendMessageV2(
            _receiver,
            _amountIn,
            _dstChainId,
            _srcSwap,
            _dstSwap,
            _maxBridgeSlippage,
            _fee,
            _srcSwap.path[_srcSwap.path.length - 1]
        );
    }

    /**
     * @notice Sends a cross-chain transfer via the liquidity pool-based bridge and sends a message specifying a wanted swap action on the
               destination chain via the message bus
     * @param _receiver the app contract that implements the MessageReceiver abstract contract
     *        NOTE not to be confused with the receiver field in SwapInfoV2 which is an EOA address of a user
     * @param _amountIn the input amount that the user wants to swap and/or bridge
     * @param _dstChainId destination chain ID
     * @param _srcSwap a struct containing swap related requirements
     * @param _dstSwap a struct containing swap related requirements
     * @param _maxBridgeSlippage the max acceptable slippage at bridge, given as percentage in point (pip). Eg. 5000 means 0.5%.
     *        Must be greater than minimalMaxSlippage. Receiver is guaranteed to receive at least (100% - max slippage percentage) * amount or the
     *        transfer can be refunded.
     * @param _fee the fee to pay to MessageBus.
     */
    function _swapAndSendMessageV2(
        address _receiver,
        uint256 _amountIn,
        uint64 _dstChainId,
        SwapInfoV2 calldata _srcSwap,
        SwapInfoDest calldata _dstSwap,
        uint32 _maxBridgeSlippage,
        uint256 _fee,
        address _outputToken
    ) private {
        BaseCrossChainParams memory _baseParams = BaseCrossChainParams(
            _srcSwap.path[0],
            _amountIn,
            _dstChainId,
            _retrieveDstTokenAddress(_dstSwap),
            _dstSwap.amountOutMinimum,
            msg.sender,
            _dstSwap.integrator,
            _srcSwap.dex
        );

        require(_srcSwap.path.length > 1, 'empty swap path');

        (bool success, uint256 srcAmtOut) = _trySwapV2(_srcSwap, _amountIn);

        bytes32 id = _sendMessage(
            _receiver,
            uint64(_baseParams.dstChainID),
            _dstSwap,
            _maxBridgeSlippage,
            _beforeSwapAndSendMessage(),
            _fee,
            _outputToken,
            srcAmtOut,
            success
        );

        emit CrossChainRequestSent(id, _baseParams);
    }

    function _trySwapV2(SwapInfoV2 memory _swap, uint256 _amount) internal returns (bool ok, uint256 amountOut) {
        if (!availableRouters.contains(_swap.dex)) {
            return (false, 0);
        }

        SmartApprove.smartApprove(_swap.path[0], _amount, _swap.dex);

        try
            IUniswapV2Router02(_swap.dex).swapExactTokensForTokens(
                _amount,
                _swap.amountOutMinimum,
                _swap.path,
                address(this),
                _swap.deadline
            )
        returns (uint256[] memory amounts) {
            return (true, amounts[amounts.length - 1]);
        } catch {
            return (false, 0);
        }
    }
}