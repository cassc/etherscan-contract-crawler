// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

interface IInvestmentEarnings {
    event NotedCancelReinvest(string orderId);
    event NotedWithdraw(uint64[] recordIds);
    event Liquidated(string orderId);
    event Processed(string orderId);

    function noteCancelReinvest(string calldata orderId) external;

    function noteWithdrawal(uint64[] calldata recordIds) external;

    function liquidatedAssets(string calldata orderId) external;

    function processBorrowing(string calldata orderId) external;
}