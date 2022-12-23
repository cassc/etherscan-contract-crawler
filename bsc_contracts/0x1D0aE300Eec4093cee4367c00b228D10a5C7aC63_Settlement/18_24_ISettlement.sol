// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@1inch/limit-order-protocol-contract/contracts/interfaces/IInteractionNotificationReceiver.sol";
import "./IFeeBankCharger.sol";

interface ISettlement is IInteractionNotificationReceiver, IFeeBankCharger {
    function settleOrders(bytes calldata order) external;
}