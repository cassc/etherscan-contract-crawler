// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../../librairies/LibOrder.sol";
import "../../librairies/LibDirectTransfer.sol";

interface IExchangeV2 {
    function matchOrders(
        LibOrder.Order memory orderLeft,
        bytes memory signatureLeft,
        LibOrder.Order memory orderRight,
        bytes memory signatureRight
    ) external payable;

    function directPurchase(LibDirectTransfer.Purchase calldata direct) external payable;
}