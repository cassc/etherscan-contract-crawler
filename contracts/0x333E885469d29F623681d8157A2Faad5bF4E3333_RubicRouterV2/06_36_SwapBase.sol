// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9;

import 'rubic-bridge-base/contracts/architecture/WithDestinationFunctionality.sol';

import 'rubic-bridge-base/contracts/libraries/SmartApprove.sol';

import '../framework/MessageSenderApp.sol';
import '../../interfaces/IWETH.sol';

contract SwapBase is MessageSenderApp, WithDestinationFunctionality {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    address public nativeWrap;
    uint64 public nonce;

    mapping(bytes32 => RefundData) public refundDetails;

    modifier isTransit(address _transitToken, address _tokenInPath) {
        checkIsTransit(_transitToken, _tokenInPath);
        _;
    }

    // ============== struct for refunds ==============

    struct RefundData {
        address integrator; // integrator address in order to take commission
        address token; // transit token
        uint256 amount; // amount of transit token
        address to; // recipient
        bool nativeOut; // receive wrapped/native
    }

    // ============== struct for V2 like dexes ==============

    struct SwapInfoV2 {
        address dex; // the DEX to use for the swap
        // if this array has only one element, it means no need to swap
        address[] path;
        // the following fields are only needed if path.length > 1
        uint256 deadline; // deadline for the swap
        uint256 amountOutMinimum; // minimum receive amount for the swap
    }

    // ============== struct for V3 like dexes ==============

    struct SwapInfoV3 {
        address dex; // the DEX to use for the swap
        bytes path;
        uint256 deadline;
        uint256 amountOutMinimum;
    }

    // ============== struct for inch swap ==============

    struct SwapInfoInch {
        address dex;
        // path is tokenIn, tokenOut
        address[] path;
        bytes data;
        uint256 amountOutMinimum;
    }

    // ============== struct dstSwap ==============
    // This is needed to make v2 -> SGN -> v3 swaps and etc.

    struct SwapInfoDest {
        address dex; // dex address
        bool nativeOut;
        address receiverEOA; // EOA recipient in dst chain
        address integrator;
        SwapVersion version; // identifies swap type
        address[] path; // path address for v2 and inch
        bytes pathV3; // path address for v3
        uint256 deadline; // for v2 and v3
        uint256 amountOutMinimum;
    }

    struct SwapRequestDest {
        SwapInfoDest swap;
        uint64 nonce;
        uint64 dstChainId;
    }

    enum SwapVersion {
        v2,
        v3,
        bridge
    }

    // ============== common checks for src swaps ==============

    function _deriveFeeAndPerformChecksNative(
        uint256 _amountIn,
        uint64 _dstChainId,
        address _integrator,
        address srcInputToken
    ) internal onlyEOA whenNotPaused returns (uint256 _fee) {
        require(srcInputToken == nativeWrap, 'token mismatch');
        require(msg.value >= _amountIn, 'amount insufficient');
        IWETH(nativeWrap).deposit{value: _amountIn}();

        _fee = accrueFixedAndGasFees(_integrator, integratorToFeeInfo[_integrator], _dstChainId) - _amountIn;
    }

    function _deriveFeeAndPerformChecks(
        uint256 _amountIn,
        uint64 _dstChainId,
        address _integrator,
        address srcInputToken
    ) internal onlyEOA whenNotPaused returns (uint256 _fee) {
        IERC20Upgradeable(srcInputToken).safeTransferFrom(msg.sender, address(this), _amountIn);

        _fee = accrueFixedAndGasFees(_integrator, integratorToFeeInfo[_integrator], _dstChainId);
    }

    // ============== Celer call ==============

    function _sendMessage(
        address _receiver,
        uint64 _dstChainId,
        SwapInfoDest calldata _dstSwap,
        uint32 _maxBridgeSlippage,
        uint64 _nonce,
        uint256 _fee,
        address _srcOutputToken,
        uint256 _srcAmtOut,
        bool _success
    ) internal returns (bytes32 id) {
        if (!_success) revert('src swap failed');

        require(_srcAmtOut >= minTokenAmount[_srcOutputToken], 'less than min');
        if (maxTokenAmount[_srcOutputToken] > 0) {
            require(_srcAmtOut <= maxTokenAmount[_srcOutputToken], 'greater than max');
        }

        id = _crossChainTransferWithSwap(
            _receiver,
            _dstChainId,
            _dstSwap,
            _maxBridgeSlippage,
            _nonce,
            _fee,
            _srcOutputToken,
            _srcAmtOut
        );
    }

    function _crossChainTransferWithSwap(
        address _receiver,
        uint64 _dstChainId,
        SwapInfoDest calldata _dstSwap,
        uint32 _maxBridgeSlippage,
        uint64 _nonce,
        uint256 _fee,
        address srcOutputToken,
        uint256 srcAmtOut
    ) private returns (bytes32 id) {
        // todo increment nonce in compute ...
        require(_dstSwap.path.length > 0, 'empty dst swap path');
        bytes memory message = abi.encode(
            SwapRequestDest({swap: _dstSwap, nonce: nonce, dstChainId: _dstChainId})
        );
        id = _computeSwapRequestId(_dstSwap.receiverEOA, uint64(block.chainid), _dstChainId, message);

        sendMessageWithTransfer(
            _receiver,
            srcOutputToken,
            srcAmtOut,
            _dstChainId,
            _nonce,
            _maxBridgeSlippage,
            message,
            _fee
        );
    }

    // ============== Utilities ==============

    function _beforeSwapAndSendMessage() internal returns (uint64) {
        return ++nonce;
    }

    function _retrieveDstTokenAddress(SwapInfoDest memory _swapInfo) internal pure returns (address) {
        if (_swapInfo.version == SwapVersion.v3) {
            require(_swapInfo.pathV3.length > 20, 'dst swap expected');

            return address(_getLastBytes20(_swapInfo.pathV3));
        } else if (_swapInfo.version == SwapVersion.v2) {
            require(_swapInfo.path.length > 1, 'dst swap expected');

            return _swapInfo.path[_swapInfo.path.length - 1];
        } else {
            require(_swapInfo.path.length == 1, 'dst bridge expected');
            return _swapInfo.path[0];
        }
    }

    // returns address of first token for V3
    function _getFirstBytes20(bytes memory input) internal pure returns (bytes20 result) {
        assembly {
            result := mload(add(input, 32))
        }
    }

    // returns address of tokenOut for V3
    function _getLastBytes20(bytes memory input) internal pure returns (bytes20 result) {
        uint256 offset = input.length + 12;
        assembly {
            result := mload(add(input, offset))
        }
    }

    function _computeSwapRequestId(
        address _receiverEOA,
        uint64 _srcChainId,
        uint64 _dstChainId,
        bytes memory _message
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_receiverEOA, _srcChainId, _dstChainId, _message));
    }

    /**
     * @dev Function to check if the address in path is transit token received from Celer
     */
    function checkIsTransit(address _transitToken, address _tokenInPath) internal pure {
        require(_transitToken == _tokenInPath, 'first token must be transit');
    }
}