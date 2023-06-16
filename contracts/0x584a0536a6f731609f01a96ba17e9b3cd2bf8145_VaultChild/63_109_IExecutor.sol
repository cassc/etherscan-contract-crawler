// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

enum ExecutorIntegration {
    ZeroX,
    GMX
}

enum ExecutorAction {
    Swap,
    PerpLongIncrease,
    PerpShortIncrease,
    PerpLongDecrease,
    PerpShortDecrease
}

interface IExecutor {
    event ExecutedManagerAction(
        ExecutorIntegration indexed integration,
        ExecutorAction indexed action,
        address inputToken,
        uint inputTokenAmount,
        address outputToken,
        uint outputTokenAmount
    );

    event ExecutedCallback(
        ExecutorIntegration indexed integration,
        ExecutorAction indexed action,
        address inputToken,
        address outputToken,
        bool cancelled
    );
}