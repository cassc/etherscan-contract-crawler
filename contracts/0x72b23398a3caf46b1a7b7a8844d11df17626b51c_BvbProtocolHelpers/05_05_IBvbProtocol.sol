// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IBvbProtocol {
    struct Order {
        uint premium;
        uint collateral;
        uint validity;
        uint expiry;
        uint nonce;
        uint16 fee;
        address maker;
        address asset;
        address collection;
        bool isBull;
    }

    struct SellOrder {
        bytes32 orderHash;
        uint price;
        uint start;
        uint end;
        uint nonce;
        address maker;
        address asset;
        address[] whitelist;
        bool isBull;
    }

    function fee() external view returns (uint16);

    function hashOrder(Order memory order) external view returns (bytes32);

    function hashSellOrder(SellOrder memory sellOrder) external view returns (bytes32);

    function checkIsValidOrder(Order calldata order, bytes32 orderHash, bytes calldata signature) external view;

    function checkIsValidSellOrder(SellOrder calldata sellOrder, bytes32 sellOrderHash, Order memory order, bytes32 orderHash, bytes calldata signature) external view;
}