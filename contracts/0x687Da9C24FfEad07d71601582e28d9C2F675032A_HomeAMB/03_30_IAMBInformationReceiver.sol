// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface IAMBInformationReceiver {
    function onInformationReceived(
        bytes32 messageId,
        bool status,
        bytes memory result
    ) external;
}