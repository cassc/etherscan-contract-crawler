// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct PurchaseParams {
    uint128 slicerId;
    uint32 quantity;
    address currency;
    uint32 productId;
    bytes buyerCustomData;
}