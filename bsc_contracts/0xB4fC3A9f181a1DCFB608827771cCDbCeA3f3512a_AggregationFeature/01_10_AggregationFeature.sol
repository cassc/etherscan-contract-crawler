// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "../interfaces/IBKFees.sol";
import "../interfaces/IBKRegistry.sol";
import "../utils/TransferHelper.sol";

import {
    BasicParams,
    AggregationParams,
    SwapType,
    OrderInfo
} from "../interfaces/IBKStructsAndEnums.sol";

import { 
    IBKErrors
} from "../interfaces/IBKErrors.sol";

library AggregationFeature {
    string public constant FEATURE_NAME = "BitKeep SOR: Aggregation Feature";
    string public constant FEATURE_VERSION = "1.0";

    address public constant BK_FEES = 0xE4DA6f981a78b8b9edEfE4D7a955C04bA7e67D8D;
    address public constant BK_REGISTRY = 0x9aFD2948F573DD8684347924eBcE1847D50621eD;

    bytes4 public constant FUNC_SWAP = bytes4(keccak256(bytes("swap(AggregationFeature.SwapDetail)"))); // 0x6a2b69f0
   
    event BKSwapV2(
        SwapType indexed swapType,
        address indexed receiver,
        uint feeAmount,
        string featureName,
        string featureVersion
    );

    event OrderInfoEvent(
        bytes transferId,
        uint dstChainId,
        address sender,
        address bridgeReceiver,
        address tokenIn,
        address desireToken,
        uint amount
    );

    struct SwapDetail {
        BasicParams basicParams;
        AggregationParams aggregationParams;
        OrderInfo orderInfo;
    }

    function swap(SwapDetail calldata swapDetail) public {
        if(!IBKRegistry(BK_REGISTRY).isCallTarget(FUNC_SWAP, swapDetail.aggregationParams.callTarget)) {
            revert IBKErrors.IllegalCallTarget();
        }

        if(!IBKRegistry(BK_REGISTRY).isApproveTarget(FUNC_SWAP, swapDetail.aggregationParams.approveTarget)) {
            revert IBKErrors.IllegalApproveTarget();
        }

       (address feeTo, address altcoinFeeTo, uint feeRate) = IBKFees(BK_FEES).getFeeTo();

        if(swapDetail.basicParams.swapType > SwapType.WHITE_TO_TOKEN) {
            revert IBKErrors.SwapTypeNotAvailable();
        }

        if(swapDetail.basicParams.swapType == SwapType.FREE) {
            _swapForFree(swapDetail);
        } else if(swapDetail.basicParams.swapType == SwapType.ETH_TOKEN) {
            if(msg.value < swapDetail.basicParams.amountInForSwap) {
                revert IBKErrors.SwapEthBalanceNotEnough();
            }
            _swapEth2Token(swapDetail, payable(feeTo), feeRate);
        } else {
            _swapToken2Others(swapDetail, payable(feeTo), altcoinFeeTo, feeRate);
        }
    }

    function _swapForFree(SwapDetail calldata swapDetail) internal {
        IBKFees(BK_FEES).checkIsSigner(
            swapDetail.basicParams.signParams.nonceHash,
            swapDetail.basicParams.signParams.signature
        );

        IERC20 fromToken = IERC20(swapDetail.basicParams.fromTokenAddress);

        bool toTokenIsETH = TransferHelper.isETH(swapDetail.basicParams.toTokenAddress);

        if(TransferHelper.isETH(swapDetail.basicParams.fromTokenAddress)) {
            if(msg.value < swapDetail.basicParams.amountInForSwap) {
                revert IBKErrors.SwapEthBalanceNotEnough();
            }
        } else {
            uint fromBalanceOfThis = fromToken.balanceOf(address(this));

            if(fromBalanceOfThis < swapDetail.basicParams.amountInTotal) {
                revert IBKErrors.BurnToMuch();
            }

            TransferHelper.approveMax(
                fromToken,
                swapDetail.aggregationParams.approveTarget,
                swapDetail.basicParams.amountInTotal
            );
        }

        uint balanceOfThis = 
            toTokenIsETH ?
            address(this).balance : IERC20(swapDetail.basicParams.toTokenAddress).balanceOf(address(this));

        (bool success, ) = swapDetail.aggregationParams.callTarget.call{value: msg.value}(swapDetail.aggregationParams.data);
        _checkCallResult(success);

        uint balanceNow = 
            toTokenIsETH ?
            address(this).balance : IERC20(swapDetail.basicParams.toTokenAddress).balanceOf(address(this));

        if(toTokenIsETH) {
            TransferHelper.safeTransferETH(swapDetail.basicParams.receiver, balanceNow - balanceOfThis);
        } else {
            TransferHelper.safeTransfer(swapDetail.basicParams.toTokenAddress, swapDetail.basicParams.receiver, balanceNow - balanceOfThis);
        }

        emit BKSwapV2(
            swapDetail.basicParams.swapType,
            swapDetail.basicParams.receiver,
            0,
            FEATURE_NAME,
            FEATURE_VERSION
        );

        emit OrderInfoEvent(
            swapDetail.orderInfo.transferId,
            swapDetail.orderInfo.dstChainId,
            msg.sender,
            swapDetail.orderInfo.bridgeReceiver,
            swapDetail.basicParams.fromTokenAddress,
            swapDetail.orderInfo.desireToken,
            balanceNow - balanceOfThis
        );
    }

    function _swapEth2Token(SwapDetail calldata swapDetail, address payable _feeTo, uint _feeRate) internal {
        IERC20 toToken = IERC20(swapDetail.basicParams.toTokenAddress);

        uint beforeBalanceOfToken = toToken.balanceOf(address(this));

        uint feeAmount = swapDetail.basicParams.amountInTotal * _feeRate / 1e4;
        TransferHelper.safeTransferETH(_feeTo, feeAmount);

        (bool success, ) = swapDetail.aggregationParams.callTarget.call{value: swapDetail.basicParams.amountInForSwap}(swapDetail.aggregationParams.data);

        _checkCallResult(success);

        uint afterBalanceOfToken = toToken.balanceOf(address(this));

        TransferHelper.safeTransfer(
            swapDetail.basicParams.toTokenAddress,
            swapDetail.basicParams.receiver,
            afterBalanceOfToken - beforeBalanceOfToken
        );

        emit BKSwapV2(
            swapDetail.basicParams.swapType,
            swapDetail.basicParams.receiver,
            feeAmount,
            FEATURE_NAME,
            FEATURE_VERSION
        );

        emit OrderInfoEvent(
            swapDetail.orderInfo.transferId,
            swapDetail.orderInfo.dstChainId,
            msg.sender,
            swapDetail.orderInfo.bridgeReceiver,
            swapDetail.basicParams.fromTokenAddress,
            swapDetail.orderInfo.desireToken,
            afterBalanceOfToken - beforeBalanceOfToken
        );
    }

    function _swapToken2Others(SwapDetail calldata swapDetail, address feeTo, address altcoinFeeTo, uint feeRate) internal {
        IERC20 fromToken = IERC20(swapDetail.basicParams.fromTokenAddress);

        uint balanceOfThis = fromToken.balanceOf(address(this));

        if(balanceOfThis < swapDetail.basicParams.amountInTotal) {
            revert IBKErrors.BurnToMuch();
        }

        TransferHelper.approveMax(
            fromToken,
            swapDetail.aggregationParams.approveTarget,
            swapDetail.basicParams.amountInTotal
        );

        if(swapDetail.basicParams.swapType == SwapType.TOKEN_ETH) {
            _swapToken2ETH(swapDetail, payable(feeTo), feeRate);
        } else if(swapDetail.basicParams.swapType == SwapType.TOKEN_TO_WHITE) {
            _swapToken2white(swapDetail, feeTo, feeRate);
        } else {
            _swapToken2token(
                swapDetail,
                swapDetail.basicParams.swapType == SwapType.TOKEN_TOKEN ? altcoinFeeTo : feeTo,
                feeRate
            );
        }
    }

    function _swapToken2ETH(SwapDetail calldata swapDetail, address payable _feeTo, uint _feeRate) internal {
        uint balanceBefore = address(this).balance;
        uint feeAmount;
        uint swappedAmount;

        (bool success, ) = swapDetail.aggregationParams.callTarget.call{value: 0}(swapDetail.aggregationParams.data);
        _checkCallResult(success);
        
        swappedAmount = address(this).balance - balanceBefore;

        feeAmount = swappedAmount * _feeRate / 1e4;
        TransferHelper.safeTransferETH(_feeTo, feeAmount);

        TransferHelper.safeTransferETH(swapDetail.basicParams.receiver, swappedAmount - feeAmount);
        
        emit BKSwapV2(
            swapDetail.basicParams.swapType,
            swapDetail.basicParams.receiver,
            feeAmount,
            FEATURE_NAME,
            FEATURE_VERSION
        );

        emit OrderInfoEvent(
            swapDetail.orderInfo.transferId,
            swapDetail.orderInfo.dstChainId,
            msg.sender,
            swapDetail.orderInfo.bridgeReceiver,
            swapDetail.basicParams.fromTokenAddress,
            swapDetail.orderInfo.desireToken,
            swappedAmount - feeAmount
        );
    }

    function _swapToken2token(SwapDetail calldata swapDetail, address _feeTo, uint _feeRate) internal {
        IERC20 toToken = IERC20(swapDetail.basicParams.toTokenAddress);
        uint balanceBefore = toToken.balanceOf(address(this));
        uint feeAmount;

        feeAmount = swapDetail.basicParams.amountInTotal * _feeRate / 1e4;
        TransferHelper.safeTransfer(swapDetail.basicParams.fromTokenAddress, _feeTo, feeAmount);

        (bool success, ) = swapDetail.aggregationParams.callTarget.call{value: 0}(swapDetail.aggregationParams.data);
        _checkCallResult(success);

        uint balanceAfter = toToken.balanceOf(address(this));
        
        TransferHelper.safeTransfer(
            swapDetail.basicParams.toTokenAddress,
            swapDetail.basicParams.receiver,
            balanceAfter- balanceBefore
        );

        emit BKSwapV2(
            swapDetail.basicParams.swapType,
            swapDetail.basicParams.receiver,
            feeAmount,
            FEATURE_NAME,
            FEATURE_VERSION
        );

        emit OrderInfoEvent(
            swapDetail.orderInfo.transferId,
            swapDetail.orderInfo.dstChainId,
            msg.sender,
            swapDetail.orderInfo.bridgeReceiver,
            swapDetail.basicParams.fromTokenAddress,
            swapDetail.orderInfo.desireToken,
            balanceAfter- balanceBefore
        );
    }

    function _swapToken2white(SwapDetail calldata swapDetail, address _feeTo, uint _feeRate) internal {
        IERC20 toToken = IERC20(swapDetail.basicParams.toTokenAddress);

        uint balanceBefore = toToken.balanceOf(address(this));
        uint swappedAmount;
        uint feeAmount;

        (bool success, ) = swapDetail.aggregationParams.callTarget.call{value: 0}(swapDetail.aggregationParams.data);
        _checkCallResult(success);

        swappedAmount = toToken.balanceOf(address(this)) - balanceBefore;

        feeAmount = swappedAmount * _feeRate / 1e4;
        TransferHelper.safeTransfer(swapDetail.basicParams.toTokenAddress, _feeTo, feeAmount);

        TransferHelper.safeTransfer(swapDetail.basicParams.toTokenAddress, swapDetail.basicParams.receiver, swappedAmount - feeAmount);

        emit BKSwapV2(
            swapDetail.basicParams.swapType,
            swapDetail.basicParams.receiver,
            feeAmount,
            FEATURE_NAME,
            FEATURE_VERSION
        );
        
        emit OrderInfoEvent(
            swapDetail.orderInfo.transferId,
            swapDetail.orderInfo.dstChainId,
            msg.sender,
            swapDetail.orderInfo.bridgeReceiver,
            swapDetail.basicParams.fromTokenAddress,
            swapDetail.orderInfo.desireToken,
            swappedAmount - feeAmount
        );
    }

    function _checkCallResult(bool _success) internal pure {
        if (!_success) {
            // Copy revert reason from call
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }
}