// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9;

import './TransferSwapBase.sol';

contract TransferSwapInch is TransferSwapBase {
    using AddressUpgradeable for address payable;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    event SwapRequestSentInch(bytes32 id, uint64 dstChainId, uint256 srcAmount, address srcToken);

    function transferWithSwapInchNative(
        address _receiver,
        uint256 _amountIn,
        uint64 _dstChainId,
        SwapInfoInch calldata _srcSwap,
        SwapInfoDest calldata _dstSwap,
        uint32 _maxBridgeSlippage
    ) external payable {
        address srcInputToken = _srcSwap.path[0];
        address srcOutputToken = _srcSwap.path[_srcSwap.path.length - 1];

        uint256 _fee = _deriveFeeAndPerformChecksNative(
            _amountIn,
            _dstChainId,
            srcInputToken
        );

        _swapAndSendMessageInch(_receiver, _amountIn, _dstChainId, _srcSwap, _dstSwap, _maxBridgeSlippage, _fee, srcInputToken, srcOutputToken);
    }

    function transferWithSwapInch(
        address _receiver,
        uint256 _amountIn,
        uint64 _dstChainId,
        SwapInfoInch calldata _srcSwap,
        SwapInfoDest calldata _dstSwap,
        uint32 _maxBridgeSlippage
    ) external payable onlyEOA whenNotPaused {
        address srcInputToken = _srcSwap.path[0];
        address srcOutputToken = _srcSwap.path[_srcSwap.path.length - 1];

        uint256 _fee = _deriveFeeAndPerformChecks(
            _amountIn,
            _dstChainId,
            srcInputToken
        );

        _swapAndSendMessageInch(_receiver, _amountIn, _dstChainId, _srcSwap, _dstSwap, _maxBridgeSlippage, _fee, srcInputToken, srcOutputToken);
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
    function _swapAndSendMessageInch(
        address _receiver,
        uint256 _amountIn,
        uint64 _dstChainId,
        SwapInfoInch calldata _srcSwap,
        SwapInfoDest calldata _dstSwap,
        uint32 _maxBridgeSlippage,
        uint256 _fee,
        /// Different
        address srcInputToken,
        address srcOutputToken
    ) private {
        uint64 _chainId = uint64(block.chainid);
        uint64 _nonce = _beforeSwapAndSendMessage();

        require(_srcSwap.path.length > 1 && _dstChainId != _chainId, 'empty swap or same chainIDs');

        (bool success, uint256 srcAmtOut) = _trySwapInch(_srcSwap, _amountIn);

        bytes32 id = _sendMessage(
            _receiver,
            _chainId,
            _dstChainId,
            _dstSwap,
            _maxBridgeSlippage,
            _nonce,
            _fee,
            srcOutputToken,
            srcAmtOut,
            success
        );

        emit SwapRequestSentInch(id, _dstChainId, _amountIn, srcInputToken);
    }

    function _trySwapInch(SwapInfoInch memory _swap, uint256 _amount) internal returns (bool ok, uint256 amountOut) {
        if (!availableRouters.contains(_swap.dex)) {
            return (false, 0);
        }

        smartApprove(_swap.path[0], _amount, _swap.dex);

        IERC20Upgradeable Transit = IERC20Upgradeable(_swap.path[_swap.path.length - 1]);
        uint256 transitBalanceBefore = Transit.balanceOf(address(this));

        Address.functionCall(_swap.dex, _swap.data);

        uint256 balanceDif = Transit.balanceOf(address(this)) - transitBalanceBefore;

        if (balanceDif >= _swap.amountOutMinimum) {
            return (true, balanceDif);
        }

        return (false, 0);
    }
}