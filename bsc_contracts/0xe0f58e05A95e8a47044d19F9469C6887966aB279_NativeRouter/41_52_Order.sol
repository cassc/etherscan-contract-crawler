// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./BytesLib.sol";

//import "hardhat/console.sol";

library Orders {
    using BytesLib for bytes;

    struct Order {
        uint256 id;
        address signer;
        address buyer;
        address seller;
        address buyerToken;
        address sellerToken;
        uint256 buyerTokenAmount;
        uint256 sellerTokenAmount;
        uint256 deadlineTimestamp;
        address txOrigin;
        bytes16 quoteId;
    }

    uint256 private constant ADDR_SIZE = 20;
    uint256 private constant UINT256_SIZE = 32;
    uint256 private constant UUID_SIZE = 16;
    uint256 private constant ORDER_SIZE = ADDR_SIZE * 6 + UINT256_SIZE * 4 + UUID_SIZE;
    uint256 private constant SIG_SIZE = 65;
    uint256 private constant HOP_SIZE = SIG_SIZE + ORDER_SIZE;

    function hasMultiplePools(bytes memory orders) internal pure returns (bool) {
        return orders.length > HOP_SIZE;
    }

    function numPools(bytes memory orders) internal pure returns (uint256) {
        // Ignore the first token address. From then on every fee and token offset indicates a pool.
        return (orders.length / HOP_SIZE);
    }

    function decodeFirstOrder(
        bytes memory orders
    ) internal pure returns (Order memory order, bytes memory signature) {
        require(
            orders.length != 0 && orders.length % HOP_SIZE == 0,
            "Orders: decodeFirstOrder: invalid bytes length"
        );
        order.id = orders.toUint256(0);
        order.signer = orders.toAddress(UINT256_SIZE);
        order.buyer = orders.toAddress(UINT256_SIZE + ADDR_SIZE);
        order.seller = orders.toAddress(UINT256_SIZE + ADDR_SIZE * 2);
        order.buyerToken = orders.toAddress(UINT256_SIZE + ADDR_SIZE * 3);
        order.sellerToken = orders.toAddress(UINT256_SIZE + ADDR_SIZE * 4);
        order.buyerTokenAmount = orders.toUint256(UINT256_SIZE + ADDR_SIZE * 5);
        order.sellerTokenAmount = orders.toUint256(UINT256_SIZE * 2 + ADDR_SIZE * 5);
        order.deadlineTimestamp = orders.toUint256(UINT256_SIZE * 3 + ADDR_SIZE * 5);
        order.txOrigin = orders.toAddress(UINT256_SIZE * 4 + ADDR_SIZE * 5);
        order.quoteId = bytes16(orders.slice(UINT256_SIZE * 4 + ADDR_SIZE * 6, UUID_SIZE));
        signature = orders.slice(ORDER_SIZE, SIG_SIZE);
    }

    function getFirstOrder(bytes memory orders) internal pure returns (bytes memory) {
        return orders.slice(0, HOP_SIZE);
    }

    function skipOrder(bytes memory orders) internal pure returns (bytes memory) {
        require(
            orders.length != 0 && orders.length % HOP_SIZE == 0,
            "Orders: decodeFirstOrder: invalid bytes length"
        );
        return orders.slice(HOP_SIZE, orders.length - HOP_SIZE);
    }
}