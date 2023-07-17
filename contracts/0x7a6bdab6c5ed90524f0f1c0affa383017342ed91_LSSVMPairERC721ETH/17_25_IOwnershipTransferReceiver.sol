// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.4;

interface IOwnershipTransferReceiver {
    function onOwnershipTransferred(address oldOwner, bytes memory data) external payable;
}