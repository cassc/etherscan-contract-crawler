// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "../lib/weth/IWETH.sol";
import "../lib/uniswapv3/ISwapRouterUniV3.sol";
import { ICurvePool, ICurveEthPool } from "../lib/curve/ICurve.sol";
import { ICurveV2Pool, ICurveV2EthPool, IGenericFactoryZap } from "../lib/curve/ICurveV2.sol";
import { IBalancerV2Vault } from "../lib/balancerv2/IBalancerV2Vault.sol";
import "../fee/FeeModel.sol";
import "./IRouter.sol";

contract DirectSwap is FeeModel, IRouter {
    using SafeMath for uint256;

    address private constant ETH_IDENTIFIER = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    uint256 private constant MAX_INT = 2**256 - 1;

    address public immutable weth;

    constructor(
        address _weth,
        uint256 _partnerSharePercent,
        uint256 _maxFeePercent,
        uint256 _paraswapReferralShare,
        uint256 _paraswapSlippageShare,
        IFeeClaimer _feeClaimer
    ) FeeModel(_partnerSharePercent, _maxFeePercent, _paraswapReferralShare, _paraswapSlippageShare, _feeClaimer) {
        weth = _weth;
    }

    event SwappedDirect(
        bytes16 uuid,
        address partner,
        uint256 feePercent,
        address initiator,
        DirectSwapKind kind,
        address indexed beneficiary,
        address indexed srcToken,
        address indexed destToken,
        uint256 srcAmount,
        uint256 receivedAmount,
        uint256 expectedAmount
    );

    enum DirectSwapKind {
        UNIV3_SELL,
        UNIV3_BUY,
        CURVEV1,
        CURVEV2,
        BALV2_SELL,
        BALV2_BUY
    }

    function initialize(bytes calldata) external pure override {
        revert("METHOD NOT IMPLEMENTED");
    }

    function getKey() external pure override returns (bytes32) {
        return keccak256(abi.encodePacked("DIRECT_SWAP_ROUTER", "1.0.0"));
    }

    function directUniV3Swap(Utils.DirectUniV3 memory data) external payable {
        address fromToken = data.fromToken;
        uint256 fromAmount = data.fromAmount;
        uint256 expectedAmount = data.expectedAmount;
        require(msg.value == (fromToken == ETH_IDENTIFIER ? fromAmount : 0), "Incorrect msg.value");

        address payable beneficiary = data.beneficiary == address(0) ? msg.sender : data.beneficiary;

        transferTokensFromProxy(fromToken, fromAmount, data.permit);

        if (_isTakeFeeFromSrcToken(data.feePercent)) {
            // take fee from source token
            fromAmount = takeFromTokenFee(fromToken, fromAmount, data.partner, data.feePercent);
        }

        if (!data.isApproved) {
            Utils.approve(data.exchange, fromToken, fromAmount);
        }

        uint256 amountOut = ISwapRouterUniV3(data.exchange).exactInput{
            value: fromToken == ETH_IDENTIFIER ? fromAmount : 0
        }(
            ISwapRouterUniV3.ExactInputParams({
                path: data.path,
                recipient: address(this),
                deadline: data.deadline,
                amountIn: fromAmount,
                amountOutMinimum: 1
            })
        );

        if (data.toToken == ETH_IDENTIFIER) {
            IWETH(weth).withdraw(amountOut);
        }

        uint256 receivedAmount = afterSell(
            data.toToken,
            data.toAmount,
            beneficiary,
            data.feePercent,
            data.partner,
            data.expectedAmount,
            0
        );

        emit SwappedDirect(
            data.uuid,
            data.partner,
            data.feePercent,
            msg.sender,
            DirectSwapKind.UNIV3_SELL,
            beneficiary,
            fromToken,
            data.toToken,
            fromAmount,
            receivedAmount,
            expectedAmount
        );
    }

    function directUniV3Buy(Utils.DirectUniV3 memory data) external payable {
        address fromToken = data.fromToken;
        require(msg.value == (fromToken == ETH_IDENTIFIER ? data.fromAmount : 0), "Incorrect msg.value");

        address payable beneficiary = data.beneficiary == address(0) ? msg.sender : data.beneficiary;

        transferTokensFromProxy(fromToken, data.fromAmount, data.permit);

        if (!data.isApproved) {
            Utils.approve(data.exchange, fromToken, data.fromAmount);
        }

        ISwapRouterUniV3(data.exchange).exactOutput{ value: fromToken == ETH_IDENTIFIER ? data.fromAmount : 0 }(
            ISwapRouterUniV3.ExactOutputParams({
                path: data.path,
                recipient: address(this),
                deadline: data.deadline,
                amountOut: data.toAmount,
                amountInMaximum: MAX_INT
            })
        );

        if (data.fromToken == ETH_IDENTIFIER) {
            ISwapRouterUniV3(data.exchange).refundETH();
        }

        if (data.toToken == ETH_IDENTIFIER) {
            IWETH(weth).withdraw(data.toAmount);
        }

        (uint256 amountIn, uint256 receivedAmount) = afterBuy(
            fromToken,
            data.toToken,
            data.fromAmount,
            data.toAmount,
            beneficiary,
            data.feePercent,
            data.partner,
            data.expectedAmount
        );

        emit SwappedDirect(
            data.uuid,
            data.partner,
            data.feePercent,
            msg.sender,
            DirectSwapKind.UNIV3_BUY,
            beneficiary,
            data.fromToken,
            data.toToken,
            amountIn,
            receivedAmount,
            data.expectedAmount
        );
    }

    function directCurveV1Swap(Utils.DirectCurveV1 memory data) external payable {
        address fromToken = data.fromToken;
        uint256 fromAmount = data.fromAmount;
        uint256 expectedAmount = data.expectedAmount;
        require(msg.value == (fromToken == ETH_IDENTIFIER ? fromAmount : 0), "Incorrect msg.value");

        address payable beneficiary = data.beneficiary == address(0) ? msg.sender : data.beneficiary;

        transferTokensFromProxy(fromToken, fromAmount, data.permit);

        if (_isTakeFeeFromSrcToken(data.feePercent)) {
            // take fee from source token
            fromAmount = takeFromTokenFee(fromToken, fromAmount, data.partner, data.feePercent);
        }

        bool isFromTokenNativeAndNeedToWrap = fromToken == ETH_IDENTIFIER && data.needWrapNative == true;

        if (isFromTokenNativeAndNeedToWrap) {
            IWETH(weth).deposit{ value: fromAmount }();
        }

        if (!data.isApproved) {
            Utils.approve(data.exchange, isFromTokenNativeAndNeedToWrap ? weth : fromToken, fromAmount);
        }

        if (data.swapType == Utils.CurveSwapType.EXCHANGE_UNDERLYING) {
            ICurvePool(data.exchange).exchange_underlying(data.i, data.j, fromAmount, 1);
        } else {
            if (address(fromToken) == ETH_IDENTIFIER && data.needWrapNative == false) {
                ICurveEthPool(data.exchange).exchange{ value: fromAmount }(data.i, data.j, fromAmount, 1);
            } else {
                ICurvePool(data.exchange).exchange(data.i, data.j, fromAmount, 1);
            }
        }

        uint256 receivedAmount;
        if (address(data.toToken) == ETH_IDENTIFIER && data.needWrapNative == true) {
            receivedAmount = Utils.tokenBalance(weth, address(this));
            IWETH(weth).withdraw(receivedAmount);
        }

        receivedAmount = afterSell(
            data.toToken,
            data.toAmount,
            beneficiary,
            data.feePercent,
            data.partner,
            expectedAmount,
            receivedAmount
        );

        emit SwappedDirect(
            data.uuid,
            data.partner,
            data.feePercent,
            msg.sender,
            DirectSwapKind.CURVEV1,
            beneficiary,
            fromToken,
            data.toToken,
            fromAmount,
            receivedAmount,
            expectedAmount
        );
    }

    function directCurveV2Swap(Utils.DirectCurveV2 memory data) external payable {
        address fromToken = data.fromToken;
        uint256 fromAmount = data.fromAmount;
        uint256 expectedAmount = data.expectedAmount;
        require(msg.value == (fromToken == ETH_IDENTIFIER ? fromAmount : 0), "Incorrect msg.value");

        address payable beneficiary = data.beneficiary == address(0) ? msg.sender : data.beneficiary;

        transferTokensFromProxy(fromToken, fromAmount, data.permit);

        if (_isTakeFeeFromSrcToken(data.feePercent)) {
            // take fee from source token
            fromAmount = takeFromTokenFee(fromToken, fromAmount, data.partner, data.feePercent);
        }

        bool isFromTokenNativeAndNeedToWrap = fromToken == ETH_IDENTIFIER && data.needWrapNative == true;
        if (isFromTokenNativeAndNeedToWrap) {
            IWETH(weth).deposit{ value: fromAmount }();
        }

        if (!data.isApproved) {
            Utils.approve(data.exchange, isFromTokenNativeAndNeedToWrap ? weth : fromToken, fromAmount);
        }

        if (data.swapType == Utils.CurveSwapType.EXCHANGE_UNDERLYING) {
            ICurveV2Pool(data.exchange).exchange_underlying(data.i, data.j, fromAmount, 1);
        } else if (data.swapType == Utils.CurveSwapType.EXCHANGE_GENERIC_FACTORY_ZAP) {
            IGenericFactoryZap(data.exchange).exchange(data.poolAddress, data.i, data.j, fromAmount, 1);
        } else {
            if (address(fromToken) == ETH_IDENTIFIER && data.needWrapNative == false) {
                ICurveV2EthPool(data.exchange).exchange{ value: fromAmount }(data.i, data.j, fromAmount, 1, true);
            } else {
                ICurveV2Pool(data.exchange).exchange(data.i, data.j, fromAmount, 1);
            }
        }

        uint256 receivedAmount;
        if (address(data.toToken) == ETH_IDENTIFIER && data.needWrapNative == true) {
            receivedAmount = Utils.tokenBalance(weth, address(this));
            IWETH(weth).withdraw(receivedAmount);
        }

        receivedAmount = afterSell(
            data.toToken,
            data.toAmount,
            beneficiary,
            data.feePercent,
            data.partner,
            expectedAmount,
            receivedAmount
        );

        emit SwappedDirect(
            data.uuid,
            data.partner,
            data.feePercent,
            msg.sender,
            DirectSwapKind.CURVEV2,
            beneficiary,
            fromToken,
            data.toToken,
            fromAmount,
            receivedAmount,
            expectedAmount
        );
    }

    function directBalancerV2GivenInSwap(Utils.DirectBalancerV2 memory data) external payable {
        address fromToken = data.assets[data.swaps[0].assetInIndex];
        uint256 fromAmount = data.fromAmount;
        address toToken = data.assets[data.swaps[data.swaps.length - 1].assetOutIndex];
        uint256 expectedAmount = data.expectedAmount;

        if (fromToken == address(0)) fromToken = ETH_IDENTIFIER;
        if (toToken == address(0)) toToken = ETH_IDENTIFIER;
        require(msg.value == (fromToken == ETH_IDENTIFIER ? fromAmount : 0), "Incorrect msg.value");

        address payable beneficiary = data.beneficiary == address(0) ? msg.sender : data.beneficiary;

        transferTokensFromProxy(fromToken, fromAmount, data.permit);

        if (_isTakeFeeFromSrcToken(data.feePercent)) {
            // take fee from source token
            data.swaps[0].amount = takeFromTokenFee(fromToken, fromAmount, data.partner, data.feePercent);
            fromAmount = data.swaps[0].amount;
        }

        if (!data.isApproved) {
            Utils.approve(data.vault, fromToken, fromAmount);
        }

        IBalancerV2Vault(data.vault).batchSwap{ value: fromToken == ETH_IDENTIFIER ? fromAmount : 0 }(
            IBalancerV2Vault.SwapKind.GIVEN_IN,
            data.swaps,
            data.assets,
            data.funds,
            data.limits,
            data.deadline
        );

        uint256 receivedAmount = afterSell(
            toToken,
            data.toAmount,
            beneficiary,
            data.feePercent,
            data.partner,
            expectedAmount,
            0
        );

        emit SwappedDirect(
            data.uuid,
            data.partner,
            data.feePercent,
            msg.sender,
            DirectSwapKind.BALV2_SELL,
            beneficiary,
            fromToken,
            toToken,
            data.fromAmount,
            receivedAmount,
            expectedAmount
        );
    }

    function directBalancerV2GivenOutSwap(Utils.DirectBalancerV2 memory data) external payable {
        address fromToken = data.assets[data.swaps[data.swaps.length - 1].assetInIndex];
        address toToken = data.assets[data.swaps[0].assetOutIndex];
        uint256 expectedAmount = data.expectedAmount;

        if (fromToken == address(0)) fromToken = ETH_IDENTIFIER;
        if (toToken == address(0)) toToken = ETH_IDENTIFIER;
        require(msg.value == (fromToken == ETH_IDENTIFIER ? data.fromAmount : 0), "Incorrect msg.value");

        address payable beneficiary = data.beneficiary == address(0) ? msg.sender : data.beneficiary;

        transferTokensFromProxy(fromToken, data.fromAmount, data.permit);

        if (!data.isApproved) {
            Utils.approve(data.vault, fromToken, data.fromAmount);
        }

        IBalancerV2Vault(data.vault).batchSwap{ value: fromToken == ETH_IDENTIFIER ? data.fromAmount : 0 }(
            IBalancerV2Vault.SwapKind.GIVEN_OUT,
            data.swaps,
            data.assets,
            data.funds,
            data.limits,
            data.deadline
        );

        (uint256 amountIn, uint256 receivedAmount) = afterBuy(
            fromToken,
            toToken,
            data.fromAmount,
            data.toAmount,
            beneficiary,
            data.feePercent,
            data.partner,
            expectedAmount
        );

        emit SwappedDirect(
            data.uuid,
            data.partner,
            data.feePercent,
            msg.sender,
            DirectSwapKind.BALV2_BUY,
            beneficiary,
            fromToken,
            toToken,
            amountIn,
            receivedAmount,
            expectedAmount
        );
    }

    function afterSell(
        address toToken,
        uint256 toAmount,
        address payable beneficiary,
        uint256 feePercent,
        address payable partner,
        uint256 expectedAmount,
        uint256 proposedReceivedAmount
    ) private returns (uint256 receivedAmount) {
        receivedAmount = proposedReceivedAmount == 0
            ? Utils.tokenBalance(toToken, address(this))
            : proposedReceivedAmount;
        require(receivedAmount >= toAmount, "Received amount of tokens are less then expected");

        if (
            _getFixedFeeBps(partner, feePercent) != 0 && !_isTakeFeeFromSrcToken(feePercent) && !_isReferral(feePercent)
        ) {
            takeToTokenFeeAndTransfer(toToken, receivedAmount, beneficiary, partner, feePercent);
        } else if (receivedAmount > expectedAmount && !_isTakeFeeFromSrcToken(feePercent)) {
            takeSlippageAndTransferSell(toToken, beneficiary, partner, receivedAmount, expectedAmount, feePercent);
        } else {
            Utils.transferTokens(toToken, beneficiary, receivedAmount);
        }
    }

    function afterBuy(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 toAmount,
        address payable beneficiary,
        uint256 feePercent,
        address payable partner,
        uint256 expectedAmount
    ) private returns (uint256 amountIn, uint256 receivedAmount) {
        receivedAmount = Utils.tokenBalance(toToken, address(this));
        require(receivedAmount >= toAmount, "Received amount of tokens are less then expected");
        uint256 remainingAmount = Utils.tokenBalance(fromToken, address(this));
        amountIn = fromAmount.sub(remainingAmount);

        if (
            _getFixedFeeBps(partner, feePercent) != 0 && !_isTakeFeeFromSrcToken(feePercent) && !_isReferral(feePercent)
        ) {
            takeToTokenFeeAndTransfer(toToken, receivedAmount, beneficiary, partner, feePercent);
            // Transfer remaining token back to sender
            Utils.transferTokens(fromToken, msg.sender, remainingAmount);
        } else {
            Utils.transferTokens(toToken, beneficiary, receivedAmount);
            if (_getFixedFeeBps(partner, feePercent) != 0 && _isTakeFeeFromSrcToken(feePercent)) {
                //  take fee from source token and transfer remaining token back to sender
                takeFromTokenFeeAndTransfer(fromToken, amountIn, remainingAmount, partner, feePercent);
            } else if (amountIn < expectedAmount) {
                takeSlippageAndTransferBuy(fromToken, partner, expectedAmount, amountIn, remainingAmount, feePercent);
            } else {
                // Transfer remaining token back to sender
                Utils.transferTokens(fromToken, msg.sender, remainingAmount);
            }
        }
    }

    function transferTokensFromProxy(
        address token,
        uint256 amount,
        bytes memory permit
    ) private {
        if (token != ETH_IDENTIFIER) {
            Utils.permit(token, permit);
            tokenTransferProxy.transferFrom(token, msg.sender, address(this), amount);
        }
    }
}