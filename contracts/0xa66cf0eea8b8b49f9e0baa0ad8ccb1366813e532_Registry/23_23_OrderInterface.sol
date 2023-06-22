// SPDX-License-Identifier: MIT
// Creator: Nullion Labs

pragma solidity 0.8.11;

library OrderInterface {
    bytes32 constant ORDER_TYPEHASH =
        keccak256(
            'Order(address maker,address eventAddress,uint256 tokenId,uint256 price,uint256 salt,uint256 listingTime,uint256 expirationTime)'
        );

    struct Order {
        address maker;
        address eventAddress;
        uint256 tokenId;
        uint256 price;
        uint256 salt;
        uint256 listingTime;
        uint256 expirationTime;
    }

    function hashOrder(OrderInterface.Order memory order) internal pure returns (bytes32 hash) {
        return
            keccak256(
                abi.encode(
                    OrderInterface.ORDER_TYPEHASH,
                    order.maker,
                    order.eventAddress,
                    order.tokenId,
                    order.price,
                    order.salt,
                    order.listingTime,
                    order.expirationTime
                )
            );
    }
}