// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import {BuyOrderV1} from "../libraries/passiveorders/BuyOrderV1.sol";

interface IClowderMain {
    function executeOnPassiveBuyOrders(
        BuyOrderV1[] calldata buyOrders,
        uint256 executorPrice,
        uint256 tokenId,
        bytes calldata data
    ) external;
}