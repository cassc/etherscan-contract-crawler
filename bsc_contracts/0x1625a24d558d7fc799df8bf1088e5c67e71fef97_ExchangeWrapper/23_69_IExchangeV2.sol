// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../../exchange/ExchangeV2.sol";

import {RoyaltiesRegistry} from "../../royalties-registry/RoyaltiesRegistry.sol";
import {TransferProxy} from "../../transfer-proxy/TransferProxy.sol";
import {ERC20TransferProxy} from "../../transfer-proxy/ERC20TransferProxy.sol";

interface IExchangeV2 {
    function matchOrders(
        LibOrder.Order memory orderLeft,
        bytes memory signatureLeft,
        LibOrder.Order memory orderRight,
        bytes memory signatureRight
    ) external payable;

    function directPurchase(LibDirectTransfer.Purchase calldata direct) external payable;
}