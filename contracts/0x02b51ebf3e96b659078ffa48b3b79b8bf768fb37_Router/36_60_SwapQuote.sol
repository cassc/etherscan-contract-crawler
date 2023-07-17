// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import { SwapOperation, UnsupportedSwapOperation } from "./SwapOperation.sol";
import { SwapTask, SwapTaskOps } from "./SwapTask.sol";
import { MultiCall } from "@gearbox-protocol/core-v2/contracts/libraries/MultiCall.sol";
import { RouterResult } from "./RouterResult.sol";
import { RAY } from "@gearbox-protocol/core-v2/contracts/libraries/Constants.sol";

struct SwapQuote {
    MultiCall multiCall;
    uint256 amount;
    bool found;
    uint256 gasUsage;
}

library SwapQuoteOps {
    using SwapTaskOps for SwapTask;

    function isBetter(
        SwapQuote memory quote1,
        SwapTask memory swapTask,
        SwapQuote memory quote2,
        uint256 gasPriceUnderlying
    ) internal pure returns (bool) {
        return
            isBetter(
                quote1,
                swapTask,
                quote2,
                quote2.gasUsage,
                gasPriceUnderlying
            );
    }

    function isBetter(
        SwapQuote memory quote1,
        SwapTask memory swapTask,
        SwapQuote memory quote2,
        uint256 quote2GasUsage,
        uint256 gasPriceTargetRAY
    ) internal pure returns (bool) {
        if (!quote1.found) return false;
        if (!quote2.found) return true;

        bool isGreater = safeIsGreater(
            swapTask,
            quote1.amount,
            (quote1.gasUsage * gasPriceTargetRAY) / RAY,
            quote2.amount,
            (quote2GasUsage * gasPriceTargetRAY) / RAY
        );

        if (
            swapTask.swapOperation == SwapOperation.EXACT_INPUT ||
            swapTask.swapOperation == SwapOperation.EXACT_INPUT_ALL
        ) return isGreater;

        if (swapTask.swapOperation == SwapOperation.EXACT_OUTPUT)
            return !isGreater;

        revert UnsupportedSwapOperation(swapTask.swapOperation);
    }

    function safeIsGreater(
        SwapTask memory swapTask,
        uint256 amount1,
        uint256 gasCost1,
        uint256 amount2,
        uint256 gasCost2
    ) internal pure returns (bool isGreater) {
        if (!swapTask.isInputTask()) {
            return (amount1 + gasCost1) > (amount2 + gasCost2);
        }

        if (amount1 >= gasCost1 && amount2 >= gasCost2) {
            return (amount1 - gasCost1) > (amount2 - gasCost2);
        }

        int256 diff1 = int256(amount1) - int256(gasCost1);
        int256 diff2 = int256(amount2) - int256(gasCost2);

        return diff1 > diff2;
    }

    function trim(SwapQuote[] memory quotes)
        internal
        pure
        returns (SwapQuote[] memory trimmed)
    {
        uint256 len = quotes.length;

        if (len == 0) return quotes;

        uint256 foundLen;
        while (quotes[foundLen].found) {
            unchecked {
                ++foundLen;
                if (foundLen == len) return quotes;
            }
        }

        trimmed = new SwapQuote[](foundLen);
        for (uint256 i; i < foundLen; ) {
            trimmed[i] = quotes[i];
            unchecked {
                ++i;
            }
        }
    }

    function toRouterResult(SwapQuote memory quote)
        internal
        pure
        returns (RouterResult memory result)
    {
        if (quote.found) {
            result.amount = quote.amount;
            result.gasUsage = quote.gasUsage;
            result.calls = new MultiCall[](1);
            result.calls[0] = quote.multiCall;
        }
    }
}