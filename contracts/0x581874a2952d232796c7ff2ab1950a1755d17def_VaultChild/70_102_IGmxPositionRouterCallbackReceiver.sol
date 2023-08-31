// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IGmxPositionRouterCallbackReceiver {
    function gmxPositionCallback(
        bytes32 positionKey,
        bool isExecuted,
        bool isIncrease
    ) external;
}