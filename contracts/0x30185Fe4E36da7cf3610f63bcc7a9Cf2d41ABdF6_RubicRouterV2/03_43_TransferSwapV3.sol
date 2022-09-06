// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9;

import './TransferSwapBase.sol';
import '../../interfaces/ISwapRouter.sol';

contract TransferSwapV3 is TransferSwapBase {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    event SwapRequestSentV3(bytes32 id, uint64 dstChainId, uint256 srcAmount, address srcToken);

    function transferWithSwapV3Native(
        address _receiver,
        uint256 _amountIn,
        uint64 _dstChainId,
        SwapInfoV3 calldata _srcSwap,
        SwapInfoDest calldata _dstSwap,
        uint32 _maxBridgeSlippage
    ) external payable onlyEOA whenNotPaused {
        (address srcInputToken, address srcOutputToken) = getInputAndOutputTokenAddresses(_srcSwap.path);

        uint256 _fee = _deriveFeeAndPerformChecksNative(
            _amountIn,
            _dstChainId,
            srcInputToken
        );

        _swapAndSendMessageV3(_receiver, _amountIn, _dstChainId, _srcSwap, _dstSwap, _maxBridgeSlippage, _fee, srcInputToken, srcOutputToken);
    }

    function transferWithSwapV3(
        address _receiver,
        uint256 _amountIn,
        uint64 _dstChainId,
        SwapInfoV3 calldata _srcSwap,
        SwapInfoDest calldata _dstSwap,
        uint32 _maxBridgeSlippage
    ) external payable onlyEOA whenNotPaused {
        (address srcInputToken, address srcOutputToken) = getInputAndOutputTokenAddresses(_srcSwap.path);

        uint256 _fee = _deriveFeeAndPerformChecks(
            _amountIn,
            _dstChainId,
            srcInputToken
        );

        _swapAndSendMessageV3(_receiver, _amountIn, _dstChainId, _srcSwap, _dstSwap, _maxBridgeSlippage, _fee, srcInputToken, srcOutputToken);
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
    function _swapAndSendMessageV3(
        address _receiver,
        uint256 _amountIn,
        uint64 _dstChainId,
        SwapInfoV3 calldata _srcSwap,
        SwapInfoDest calldata _dstSwap,
        uint32 _maxBridgeSlippage,
        uint256 _fee,
        /// Different
        address srcInputToken,
        address srcOutputToken
    ) private {
        uint64 _chainId = uint64(block.chainid);
        uint64 _nonce = _beforeSwapAndSendMessage();

        require(_srcSwap.path.length > 20 && _dstChainId != _chainId, 'empty swap or same chainIDs');

        (bool success, uint256 srcAmtOut) = _trySwapV3(_srcSwap, _amountIn);

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

        emit SwapRequestSentV3(id, _dstChainId, _amountIn, srcInputToken);
    }

    function _trySwapV3(SwapInfoV3 memory _swap, uint256 _amount) internal returns (bool ok, uint256 amountOut) {
        if (!availableRouters.contains(_swap.dex)) {
            return (false, 0);
        }

        smartApprove(address(_getFirstBytes20(_swap.path)), _amount, _swap.dex);

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

    function getInputAndOutputTokenAddresses(bytes memory _path) private pure returns(address inputToken, address outputToken) {
        inputToken = address(_getFirstBytes20(_path));
        outputToken = address(_getLastBytes20(_path));
    }
}