// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import { SwapOperation, UnsupportedSwapOperation } from "./SwapOperation.sol";

import { RAY } from "@gearbox-protocol/core-v2/contracts/libraries/Constants.sol";
import { SlippageMath } from "../helpers/SlippageMath.sol";

struct SwapTask {
    SwapOperation swapOperation;
    address creditAccount;
    address tokenIn;
    address tokenOut;
    address[] connectors;
    uint256 amount;
    uint256 slippage;
    bool externalSlippage;
}

library SwapTaskOps {
    using SlippageMath for uint256;

    function amountLimit(
        SwapTask memory swapTask,
        uint256 amount,
        uint256 numSwaps
    ) internal pure returns (uint256) {
        if (swapTask.externalSlippage) return noSlippageCheckValue(swapTask);
        return amountWithSlippage(swapTask, amount, numSwaps);
    }

    function amountLimit(SwapTask memory swapTask, uint256 amount)
        internal
        pure
        returns (uint256)
    {
        if (swapTask.externalSlippage) return noSlippageCheckValue(swapTask);
        return amountWithSlippage(swapTask, amount);
    }

    function rateLimit(
        SwapTask memory swapTask,
        uint256 amount,
        uint256 numSwaps
    ) internal pure returns (uint256) {
        if (swapTask.externalSlippage) return noSlippageCheckValue(swapTask);
        return rateRAYWithSlippage(swapTask, amount, numSwaps);
    }

    function rateLimit(SwapTask memory swapTask, uint256 amount)
        internal
        pure
        returns (uint256)
    {
        if (swapTask.externalSlippage) return noSlippageCheckValue(swapTask);
        return rateRAYWithSlippage(swapTask, amount);
    }

    function amountWithSlippage(
        SwapTask memory swapTask,
        uint256 amount,
        uint256 numSwaps
    ) internal pure returns (uint256) {
        if (numSwaps == 1) return amountWithSlippage(swapTask, amount);

        if (
            swapTask.swapOperation == SwapOperation.EXACT_INPUT ||
            swapTask.swapOperation == SwapOperation.EXACT_INPUT_ALL
        ) return amount.applySlippage(swapTask.slippage, numSwaps, true);

        if (swapTask.swapOperation == SwapOperation.EXACT_OUTPUT)
            return amount.applySlippage(swapTask.slippage, numSwaps, false);

        revert UnsupportedSwapOperation(swapTask.swapOperation);
    }

    function amountWithSlippage(SwapTask memory swapTask, uint256 amount)
        internal
        pure
        returns (uint256)
    {
        if (
            swapTask.swapOperation == SwapOperation.EXACT_INPUT ||
            swapTask.swapOperation == SwapOperation.EXACT_INPUT_ALL
        ) return amount.applySlippage(swapTask.slippage, true);

        if (swapTask.swapOperation == SwapOperation.EXACT_OUTPUT)
            return amount.applySlippage(swapTask.slippage, false);

        revert UnsupportedSwapOperation(swapTask.swapOperation);
    }

    function rateRAYWithSlippage(SwapTask memory swapTask, uint256 amount)
        internal
        pure
        returns (uint256)
    {
        return (amountWithSlippage(swapTask, RAY * amount)) / swapTask.amount;
    }

    function rateRAYWithSlippage(
        SwapTask memory swapTask,
        uint256 amount,
        uint256 numSwaps
    ) internal pure returns (uint256) {
        return
            (amountWithSlippage(swapTask, RAY * amount, numSwaps)) /
            swapTask.amount;
    }

    function makeConnectorInTask(
        SwapTask memory swapTask,
        uint256 amount,
        uint256 index
    ) internal pure returns (SwapTask memory result) {
        address[] memory connectors;
        result = SwapTask({
            swapOperation: swapTask.swapOperation,
            creditAccount: swapTask.creditAccount,
            tokenIn: swapTask.tokenIn,
            tokenOut: swapTask.connectors[index],
            connectors: connectors,
            amount: amount,
            slippage: swapTask.slippage,
            externalSlippage: swapTask.externalSlippage
        });
    }

    function makeConnectorInTask(SwapTask memory swapTask, uint256 index)
        internal
        pure
        returns (SwapTask memory result)
    {
        result = makeConnectorInTask(swapTask, swapTask.amount, index);
    }

    function makeConnectorOutTask(
        SwapTask memory swapTask,
        uint256 amountIn,
        uint256 index,
        bool swapToAllInput
    ) internal pure returns (SwapTask memory result) {
        address[] memory connectors;
        result = SwapTask({
            swapOperation: swapToAllInput
                ? SwapOperation.EXACT_INPUT_ALL
                : swapTask.swapOperation,
            creditAccount: swapTask.creditAccount,
            tokenIn: swapTask.connectors[index],
            tokenOut: swapTask.tokenOut,
            connectors: connectors,
            amount: amountIn,
            slippage: swapTask.slippage,
            externalSlippage: swapTask.externalSlippage
        });
    }

    function isInputTask(SwapTask memory swapTask)
        internal
        pure
        returns (bool)
    {
        if (
            swapTask.swapOperation == SwapOperation.EXACT_INPUT ||
            swapTask.swapOperation == SwapOperation.EXACT_INPUT_ALL
        ) return true;

        if (swapTask.swapOperation == SwapOperation.EXACT_OUTPUT) return false;

        revert UnsupportedSwapOperation(swapTask.swapOperation);
    }

    function isOutputTask(SwapTask memory swapTask)
        internal
        pure
        returns (bool)
    {
        return !isInputTask(swapTask);
    }

    function noSlippageCheckValue(SwapTask memory swapTask)
        internal
        pure
        returns (uint256)
    {
        if (isInputTask(swapTask)) {
            return 0;
        } else {
            return type(uint256).max;
        }
    }
}