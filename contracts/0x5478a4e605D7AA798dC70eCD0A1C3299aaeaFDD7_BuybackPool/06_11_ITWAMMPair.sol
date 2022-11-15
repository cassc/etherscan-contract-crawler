// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface ITWAMMPair {
    struct Order {
        uint256 id;
        uint256 expirationBlock;
        uint256 saleRate;
        address owner;
        address sellTokenId;
        address buyTokenId;
    }

    function getOrderDetails(uint256 orderId)
        external
        view
        returns (Order memory);
}