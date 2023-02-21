// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { SeaportInterface } from "../interfaces/SeaportInterface.sol";
import { OrderComponents } from "../lib/ConsiderationStructs.sol";

interface CietyZoneInterface {
    function cancelOrders(
        SeaportInterface seaport,
        OrderComponents[] calldata orders
    ) external returns (bool cancelled);
}