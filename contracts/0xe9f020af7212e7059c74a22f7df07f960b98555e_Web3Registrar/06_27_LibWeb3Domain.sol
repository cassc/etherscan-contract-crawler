// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

library LibWeb3Domain {
    struct Order {
        string name;
        uint256 tokenId;
        string tokenURI;
        address owner;
        uint256 price;
        uint256 timestamp;
    }

    bytes32 public constant ORDER_TYPEHASH = keccak256("Order(string name,uint256 tokenId,string tokenURI,address owner,uint256 price,uint256 timestamp)");

    function getHash(Order memory order) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                ORDER_TYPEHASH,
                keccak256(bytes(order.name)),
                order.tokenId,
                keccak256(bytes(order.tokenURI)),
                order.owner,
                order.price,
                order.timestamp
            )
        );
    }
}