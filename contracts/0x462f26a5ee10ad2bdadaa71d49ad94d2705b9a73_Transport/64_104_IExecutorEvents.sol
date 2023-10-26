// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

enum ExecutorIntegration {
    ZeroX,
    GMX,
    SnxPerpsV2
}

enum ExecutorAction {
    Swap,
    PerpLongIncrease,
    PerpShortIncrease,
    PerpLongDecrease,
    PerpShortDecrease
}

interface IExecutorEvents {
    event ExecutedManagerAction(
        ExecutorIntegration indexed integration,
        ExecutorAction indexed action,
        address inputToken,
        uint inputTokenAmount,
        address outputToken,
        uint outputTokenAmount,
        uint price
    );

    event ExecutedCallback(
        ExecutorIntegration indexed integration,
        ExecutorAction indexed action,
        address inputToken,
        address outputToken,
        bool wasExecuted,
        uint executionPrice
    );
}