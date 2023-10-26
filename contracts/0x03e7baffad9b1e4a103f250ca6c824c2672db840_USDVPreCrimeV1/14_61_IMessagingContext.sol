// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

interface IMessagingContext {
    function isSendingMessage() external view returns (bool);

    function getSendContext() external view returns (uint32, address);
}