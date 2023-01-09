// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

library LibOrder {
    bytes32 public constant ORDER_TYPEHASH =
        keccak256(
            "Order(address maker,Asset makeAsset,Asset takeAsset,uint256 salt,uint256 deadline)Asset(uint256 typ,bytes data)"
        );
    bytes32 public constant ASSET_TYPEHASH = keccak256("Asset(uint256 typ,bytes data)");

    /// @dev Asset type
    enum AssetType {
        ERC721,
        ERC20
    }

    /// @dev Asset structure
    struct Asset {
        AssetType typ;
        bytes data;
    }

    /// @dev Order structure
    struct Order {
        address maker;
        Asset makeAsset;
        Asset takeAsset;
        uint256 salt;
        uint256 deadline;
    }

    /// @dev Computes an order hash for _hashTypedDataV4 (EIP712)
    /// @param order Order
    function hash(Order memory order) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ORDER_TYPEHASH,
                    order.maker,
                    hashAsset(order.makeAsset),
                    hashAsset(order.takeAsset),
                    order.salt,
                    order.deadline
                )
            );
    }

    /// @dev Computes key hash that is used to cancel order on chain after you've signed it via EIP712
    /// @param order Order
    function keyHash(Order memory order) internal pure returns (bytes32) {
        return keccak256(abi.encode(ORDER_TYPEHASH, order.maker, order.makeAsset.typ, order.takeAsset.typ, order.salt));
    }

    /// @dev hash helper
    /// @param asset Asset
    function hashAsset(Asset memory asset) internal pure returns (bytes32) {
        return keccak256(abi.encode(ASSET_TYPEHASH, asset.typ, keccak256(asset.data)));
    }
}