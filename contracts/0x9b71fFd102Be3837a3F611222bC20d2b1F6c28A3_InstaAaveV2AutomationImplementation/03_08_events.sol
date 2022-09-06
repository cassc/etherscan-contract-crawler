// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
pragma abicoder v2;

import "./variables.sol";

abstract contract Events is Variables {
    event LogSubmittedAutomation(
        address indexed user,
        uint32 indexed id,
        uint128 safeHF,
        uint128 thresholdHF,
        uint128 currentHf
    );

    event LogCancelledAutomation(
        address indexed user,
        uint32 indexed id,
        uint32 indexed nonce
    );

    event LogExecutedAutomation(
        address indexed user,
        uint32 indexed id,
        uint32 indexed nonce,
        ExecutionParams params,
        bool isSafe,
        uint16 automationFee,
        bytes metadata,
        uint128 finalHf,
        uint128 initialHf
    );

    event LogExecutionFailedAutomation(
        address indexed user,
        uint32 indexed id,
        uint32 indexed nonce,
        ExecutionParams params,
        bytes metadata,
        uint128 initialHf
    );

    event LogSystemCancelledAutomation(
        address indexed user,
        uint32 indexed id,
        uint32 indexed nonce,
        uint8 errorCode
    );

    event LogFlippedExecutors(address[] executors, bool[] status);

    event LogUpdatedBufferHf(uint128 oldBufferHf, uint128 newBufferHf);

    event LogUpdatedMinHf(uint128 oldMinHf, uint128 newMinHf);

    event LogUpdatedAutomationFee(
        uint16 oldAutomationFee,
        uint16 newAutomationFee
    );

    event LogFeeTransferred(
        address indexed recipient,
        address[] tokens,
        uint256[] amount
    );

    event LogChangedOwner(address indexed oldOnwer, address indexed newOnwer);

    event LogSystemCall(
        address indexed sender,
        string actionId,
        bytes metadata
    );
}