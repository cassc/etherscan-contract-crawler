// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

interface IOrderV0 {
    struct Order {
        address maker;
        address taker;
    }
}