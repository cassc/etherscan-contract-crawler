// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9;

import './SwapBase.sol';

contract TransferSwapInch is SwapBase {

    using AddressUpgradeable for address payable;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    function transferWithSwapInchNative(
        address _receiver,
        uint256 _amountIn,
        uint64 _dstChainId,
        SwapInfoInch calldata _srcSwap,
        SwapInfoDest calldata _dstSwap,
        uint32 _maxBridgeSlippage
    ) external payable {
        uint256 _fee = _deriveFeeAndPerformChecksNative(_amountIn, _dstChainId, _dstSwap.integrator, _srcSwap.path[0]);

        _swapAndSendMessageInch(
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

    function transferWithSwapInch(
        address _receiver,
        uint256 _amountIn,
        uint64 _dstChainId,
        SwapInfoInch calldata _srcSwap,
        SwapInfoDest calldata _dstSwap,
        uint32 _maxBridgeSlippage
    ) external payable {
        uint256 _fee = _deriveFeeAndPerformChecks(_amountIn, _dstChainId, _dstSwap.integrator, _srcSwap.path[0]);

        _swapAndSendMessageInch(
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
     *        NOTE not to be confused with the receiver field in SwapInfoInch which is an EOA address of a user
     * @param _amountIn the input amount that the user wants to swap and/or bridge
     * @param _dstChainId destination chain ID
     * @param _srcSwap a struct containing swap related requirements
     * @param _dstSwap a struct containing swap related requirements
     * @param _maxBridgeSlippage the max acceptable slippage at bridge, given as percentage in point (pip). Eg. 5000 means 0.5%.
     *        Must be greater than minimalMaxSlippage. Receiver is guaranteed to receive at least (100% - max slippage percentage) * amount or the
     *        transfer can be refunded.
     * @param _fee the fee to pay to MessageBus.
     */
    function _swapAndSendMessageInch(
        address _receiver,
        uint256 _amountIn,
        uint64 _dstChainId,
        SwapInfoInch calldata _srcSwap,
        SwapInfoDest calldata _dstSwap,
        uint32 _maxBridgeSlippage,
        uint256 _fee,
        address srcOutputToken
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

        (bool success, uint256 srcAmtOut) = _trySwapInch(_srcSwap, _amountIn);

        bytes32 id = _sendMessage(
            _receiver,
            uint64(_baseParams.dstChainID),
            _dstSwap,
            _maxBridgeSlippage,
            _beforeSwapAndSendMessage(),
            _fee,
            srcOutputToken,
            srcAmtOut,
            success
        );

        emit CrossChainRequestSent(id, _baseParams);
    }

    function _trySwapInch(SwapInfoInch memory _swap, uint256 _amount) internal returns (bool ok, uint256 amountOut) {
        if (!availableRouters.contains(_swap.dex)) {
            return (false, 0);
        }

        SmartApprove.smartApprove(_swap.path[0], _amount, _swap.dex);

        IERC20Upgradeable Transit = IERC20Upgradeable(_swap.path[_swap.path.length - 1]);
        uint256 transitBalanceBefore = Transit.balanceOf(address(this));

        AddressUpgradeable.functionCall(_swap.dex, _swap.data);

        uint256 balanceDif = Transit.balanceOf(address(this)) - transitBalanceBefore;

        if (balanceDif >= _swap.amountOutMinimum) {
            return (true, balanceDif);
        }

        return (false, 0);
    }
}