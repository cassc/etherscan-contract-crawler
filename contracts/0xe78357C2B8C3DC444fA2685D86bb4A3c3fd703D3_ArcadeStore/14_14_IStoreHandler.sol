// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IStoreHandler {
    function notifyPurchase(bytes32 itemId, address purchaser, uint256 quantity) external;
}