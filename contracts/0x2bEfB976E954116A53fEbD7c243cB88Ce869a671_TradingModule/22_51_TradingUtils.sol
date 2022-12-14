// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Deployments} from "../global/Deployments.sol";
import {Constants} from "../global/Constants.sol";
import {TokenUtils, IERC20} from "../utils/TokenUtils.sol";
import "../../interfaces/trading/IVaultExchange.sol";
import "../../interfaces/trading/ITradingModule.sol";
import {nProxy} from "../proxy/nProxy.sol";

/// @notice Utility library used by the trading module
library TradingUtils {
    using TokenUtils for IERC20;

    error ERC20Error();
    error TradeExecution(bytes returnData);
    error PreValidationExactIn(uint256 maxAmountIn, uint256 preTradeSellBalance);
    error PreValidationExactOut(uint256 maxAmountIn, uint256 preTradeSellBalance);
    error PostValidationExactIn(uint256 minAmountOut, uint256 amountReceived);
    error PostValidationExactOut(uint256 exactAmountOut, uint256 amountReceived);

    event TradeExecuted(
        address indexed sellToken,
        address indexed buyToken,
        uint256 sellAmount,
        uint256 buyAmount
    );

    function _executeInternal(
        Trade memory trade,
        uint16 dexId,
        address spender,
        address target,
        uint256 msgValue,
        bytes memory executionData
    ) internal returns (uint256 amountSold, uint256 amountBought) {
        // Get pre-trade token balances
        (uint256 preTradeSellBalance, uint256 preTradeBuyBalance) = _getBalances(trade);

        // Make sure we have enough tokens to sell
        _preValidate(trade, preTradeSellBalance);

        // No need to approve ETH trades
        if (spender != Deployments.ETH_ADDRESS && DexId(dexId) != DexId.NOTIONAL_VAULT) {
            _approve(trade, spender);
        }

        _executeTrade(target, msgValue, executionData, spender, trade);

        // Get post-trade token balances
        (uint256 postTradeSellBalance, uint256 postTradeBuyBalance) = _getBalances(trade);

        _postValidate(trade, postTradeBuyBalance - preTradeBuyBalance);

        // No need to revoke ETH trades
        if (spender != Deployments.ETH_ADDRESS && DexId(dexId) != DexId.NOTIONAL_VAULT) {
            IERC20(trade.sellToken).checkRevoke(spender);
        }

        amountSold = preTradeSellBalance - postTradeSellBalance;
        amountBought = postTradeBuyBalance - preTradeBuyBalance;

        emit TradeExecuted(trade.sellToken, trade.buyToken, amountSold, amountBought);
    }

    function _getBalances(Trade memory trade) private view returns (uint256, uint256) {
        return (
            trade.sellToken == Deployments.ETH_ADDRESS
                ? address(this).balance
                : IERC20(trade.sellToken).balanceOf(address(this)),
            trade.buyToken == Deployments.ETH_ADDRESS
                ? address(this).balance
                : IERC20(trade.buyToken).balanceOf(address(this))
        );
    }

    function _isExactIn(Trade memory trade) private pure returns (bool) {
        return
            trade.tradeType == TradeType.EXACT_IN_SINGLE ||
            trade.tradeType == TradeType.EXACT_IN_BATCH;
    }

    function _isExactOut(Trade memory trade) private pure returns (bool) {
        return
            trade.tradeType == TradeType.EXACT_OUT_SINGLE ||
            trade.tradeType == TradeType.EXACT_OUT_BATCH;
    }

    /// @notice we may need to unwrap excess WETH for exact out trades
    function _needsToUnwrapExcessWETH(Trade memory trade, address spender) private pure returns (bool) {
        return trade.sellToken == Deployments.ETH_ADDRESS && spender != Deployments.ETH_ADDRESS && _isExactOut(trade);
    }

    function _preValidate(Trade memory trade, uint256 preTradeSellBalance) private pure {
        if (_isExactIn(trade) && preTradeSellBalance < trade.amount) {
            revert PreValidationExactIn(trade.amount, preTradeSellBalance);
        } 
        
        if (_isExactOut(trade) && preTradeSellBalance < trade.limit) {
            // NOTE: this implies that vaults cannot execute market trades on exact out
            revert PreValidationExactOut(trade.limit, preTradeSellBalance);
        }
    }

    function _postValidate(Trade memory trade, uint256 amountReceived) private pure {
        if (_isExactIn(trade) && amountReceived < trade.limit) {
            revert PostValidationExactIn(trade.limit, amountReceived);
        }

        if (_isExactOut(trade) && amountReceived != trade.amount) {
            revert PostValidationExactOut(trade.amount, amountReceived);
        }
    }

    /// @notice Approve exchange to pull from this contract
    /// @dev approve up to trade.amount for EXACT_IN trades and up to trade.limit
    /// for EXACT_OUT trades
    function _approve(Trade memory trade, address spender) private {
        uint256 allowance = _isExactIn(trade) ? trade.amount : trade.limit;
        address sellToken = trade.sellToken;
        // approve WETH instead of ETH for ETH trades if
        // spender != address(0) (checked by the caller)
        if (sellToken == Constants.ETH_ADDRESS) {
            sellToken = address(Deployments.WETH);
        }
        IERC20(sellToken).checkApprove(spender, allowance);
    }

    function _executeTrade(
        address target,
        uint256 msgValue,
        bytes memory params,
        address spender,
        Trade memory trade
    ) private {
        uint256 preTradeBalance;
 
        if (trade.buyToken == address(Deployments.WETH)) {
            preTradeBalance = address(this).balance;
        } else if (trade.buyToken == Deployments.ETH_ADDRESS || _needsToUnwrapExcessWETH(trade, spender)) {
            preTradeBalance = IERC20(address(Deployments.WETH)).balanceOf(address(this));
        }

        if (trade.sellToken == address(Deployments.WETH) && spender == Deployments.ETH_ADDRESS) {
            // Curve doesn't support Deployments.WETH (spender == address(0))
            uint256 withdrawAmount = _isExactIn(trade) ? trade.amount : trade.limit;
            Deployments.WETH.withdraw(withdrawAmount);
        } else if (trade.sellToken == Deployments.ETH_ADDRESS && spender != Deployments.ETH_ADDRESS) {
            // UniswapV3 doesn't support ETH (spender != address(0))
            uint256 depositAmount = _isExactIn(trade) ? trade.amount : trade.limit;
            Deployments.WETH.deposit{value: depositAmount }();
        }

        (bool success, bytes memory returnData) = target.call{value: msgValue}(params);
        if (!success) revert TradeExecution(returnData);

        if (trade.buyToken == address(Deployments.WETH)) {
            if (address(this).balance > preTradeBalance) {
                // If the caller specifies that they want to receive Deployments.WETH but we have received ETH,
                // wrap the ETH to Deployments.WETH.
                uint256 depositAmount;
                unchecked { depositAmount = address(this).balance - preTradeBalance; }
                Deployments.WETH.deposit{value: depositAmount}();
            }
        } else if (trade.buyToken == Deployments.ETH_ADDRESS || _needsToUnwrapExcessWETH(trade, spender)) {
            uint256 postTradeBalance = IERC20(address(Deployments.WETH)).balanceOf(address(this));
            if (postTradeBalance > preTradeBalance) {
                // If the caller specifies that they want to receive ETH but we have received Deployments.WETH,
                // unwrap the Deployments.WETH to ETH.
                uint256 withdrawAmount;
                unchecked { withdrawAmount = postTradeBalance - preTradeBalance; }
                Deployments.WETH.withdraw(withdrawAmount);
            }
        }
    }

    function _getLimitAmount(
        TradeType tradeType,
        address sellToken,
        address buyToken,
        uint256 amount,
        uint32 slippageLimit,
        uint256 oraclePrice,
        uint256 oracleDecimals
    ) internal view returns (uint256 limitAmount) {
        uint256 sellTokenDecimals = 10 **
            (
                sellToken == Deployments.ETH_ADDRESS
                    ? 18
                    : IERC20(sellToken).decimals()
            );
        uint256 buyTokenDecimals = 10 **
            (
                buyToken == Deployments.ETH_ADDRESS
                    ? 18
                    : IERC20(buyToken).decimals()
            );

        if (tradeType == TradeType.EXACT_OUT_SINGLE || tradeType == TradeType.EXACT_OUT_BATCH) {
            // type(uint256).max means no slippage limit
            if (slippageLimit == type(uint256).max) {
                return type(uint256).max;
            }
            // For exact out trades, we need to invert the oracle price (1 / oraclePrice)
            // We increase the precision before we divide because oraclePrice is in
            // oracle decimals
            oraclePrice = (oracleDecimals * oracleDecimals) / oraclePrice;
            // For exact out trades, limitAmount is the max amount of sellToken the DEX can
            // pull from the contract
            limitAmount =
                ((oraclePrice + 
                    ((oraclePrice * uint256(slippageLimit)) /
                        Constants.SLIPPAGE_LIMIT_PRECISION)) * amount) / 
                oracleDecimals;

            // limitAmount is in buyToken precision after the previous calculation,
            // convert it to sellToken precision
            limitAmount = (limitAmount * sellTokenDecimals) / buyTokenDecimals;
        } else {
            // type(uint256).max means no slippage limit
            if (slippageLimit == type(uint256).max) {
                return 0;
            }
            // For exact in trades, limitAmount is the min amount of buyToken the contract
            // expects from the DEX
            limitAmount =
                ((oraclePrice -
                    ((oraclePrice * uint256(slippageLimit)) /
                        Constants.SLIPPAGE_LIMIT_PRECISION)) * amount) /
                oracleDecimals;

            // limitAmount is in sellToken precision after the previous calculation,
            // convert it to buyToken precision
            limitAmount = (limitAmount * buyTokenDecimals) / sellTokenDecimals;
        }
    }
}