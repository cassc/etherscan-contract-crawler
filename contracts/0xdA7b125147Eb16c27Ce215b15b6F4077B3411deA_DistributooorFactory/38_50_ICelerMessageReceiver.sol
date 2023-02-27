// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8;

interface ICelerMessageReceiver {
    enum ExecutionStatus {
        Fail,
        Success,
        Retry
    }

    function executeMessage(
        address sender,
        uint64 srcChainId,
        bytes calldata message,
        address executor
    ) external returns (ExecutionStatus);
}