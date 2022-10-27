// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Deployments} from "../../global/Deployments.sol";
import "../../../interfaces/trading/ITradingModule.sol";
import "../../../interfaces/balancer/IBalancerVault.sol";

library BalancerV2Adapter {
    struct SingleSwapData {
        bytes32 poolId;
    }

    struct BatchSwapData {
        IBalancerVault.BatchSwapStep[] swaps;
        IAsset[] assets;
        int256[] limits;
    }

    function _single(IBalancerVault.SwapKind kind, address from, Trade memory trade)
        internal pure returns (bytes memory) {
        SingleSwapData memory data = abi.decode(trade.exchangeData, (SingleSwapData));

        return abi.encodeWithSelector(
            IBalancerVault.swap.selector,
            IBalancerVault.SingleSwap(
                data.poolId,
                kind,
                IAsset(trade.sellToken),
                IAsset(trade.buyToken),
                trade.amount,
                new bytes(0) // userData
            ),
            IBalancerVault.FundManagement(
                from, // sender
                false, // fromInternalBalance
                payable(from), // recipient
                false // toInternalBalance
            ),
            trade.limit,
            trade.deadline
        );
    }

    function _batch(IBalancerVault.SwapKind kind, address from, Trade memory trade)
        internal pure returns (bytes memory) {
        BatchSwapData memory data = abi.decode(trade.exchangeData, (BatchSwapData));

        return abi.encodeWithSelector(
            IBalancerVault.batchSwap.selector,
            kind, // swapKind
            data.swaps,
            data.assets,
            IBalancerVault.FundManagement(
                from, // sender
                false, // fromInternalBalance
                payable(from), // recipient
                false // toInternalBalance
            ),
            data.limits,
            trade.deadline
        );
    }

    function getExecutionData(address from, Trade calldata trade)
        internal view returns (
            address spender,
            address target,
            uint256 msgValue,
            bytes memory executionCallData
        )
    {
        target = address(Deployments.BALANCER_VAULT);
        if (trade.sellToken == Deployments.ETH_ADDRESS) {
            spender = address(0);
            msgValue = trade.amount;
        } else {
            spender = address(Deployments.BALANCER_VAULT);
            // msgValue is zero in this case
        }

        if (TradeType(trade.tradeType) == TradeType.EXACT_IN_SINGLE) {
            executionCallData = _single(IBalancerVault.SwapKind.GIVEN_IN, from, trade);
        } else if (TradeType(trade.tradeType) == TradeType.EXACT_OUT_SINGLE) {
            executionCallData = _single(IBalancerVault.SwapKind.GIVEN_OUT, from, trade);
        } else if (TradeType(trade.tradeType) == TradeType.EXACT_IN_BATCH) {
            executionCallData = _batch(IBalancerVault.SwapKind.GIVEN_IN, from, trade);
        } else if (TradeType(trade.tradeType) == TradeType.EXACT_OUT_BATCH) {
            executionCallData = _batch(IBalancerVault.SwapKind.GIVEN_OUT, from, trade);
        }
    }
}