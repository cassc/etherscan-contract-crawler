// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "./LibAsset.sol";

library LibSignature {
    enum AuctionType {
        FixedPrice,
        English,
        Decreasing
    }

    struct Order {
        address maker;                // user making a order (buy or sell)
        LibAsset.Asset[] makeAssets;  // asset(s) being sold or used to buy
        address taker;                // optional param => who is allowed to buy or sell, ZERO_ADDRESS if public sale
        LibAsset.Asset[] takeAssets;  // desired counterAsset(s), can be empty to allow any bids
        uint256 salt;                 // unique salt to eliminate collisons
        uint256 start;                // optional: set = 0 to disregard. start Unix timestamp of when order is valid
        uint256 end;                  // optional: set = 0 to disregard. end Unix timestamp of when order is invalid
        uint256 nonce;                // nonce for all orders
        AuctionType auctionType;      // type of auction
    }

    bytes32 constant private ORDER_TYPEHASH = keccak256(
        "Order(address maker,Asset[] makeAssets,address taker,Asset[] takeAssets,uint256 salt,uint256 start,uint256 end,uint256 nonce,uint8 auctionType)Asset(AssetType assetType,bytes data)AssetType(bytes4 assetClass,bytes data)"
    );

    function _domainSeparatorV4Marketplace() internal view returns (bytes32) {
        bytes32 _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
        return keccak256(abi.encode(
            _TYPE_HASH,
            keccak256("NFT.com Marketplace"),
            keccak256("1"),
            block.chainid,
            address(this)
        ));
    }

    function _hashTypedDataV4Marketplace(bytes32 structHash) internal view returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4Marketplace(), structHash);
    }

    function getStructHash(Order calldata order, uint256 nonce) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            ORDER_TYPEHASH,
            order.maker,
            LibAsset.hash(order.makeAssets),
            order.taker,
            LibAsset.hash(order.takeAssets),
            order.salt,
            order.start,
            order.end,
            nonce,
            order.auctionType
        ));
    }

    function validate(Order calldata order) internal view {
        require(order.maker != address(0x0), "ls: !0");
        require(order.start == 0 || order.start < block.timestamp, "ls: start expired");
        require(order.end == 0 || order.end > block.timestamp, "ls: end expired");
        require(order.makeAssets.length != 0, "ls: make > 0");
        require(order.takeAssets.length != 0, "ls: take > 0");
    }

    function concatVRS(
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (bytes memory) {
        bytes memory result = new bytes(65);
        bytes1 v1 = bytes1(v);

        assembly {
            mstore(add(result, 0x20), r)
            mstore(add(result, 0x40), s)
            mstore(add(result, 0x60), v1)
        }

        return result;
    }

    function recoverVRS(bytes memory signature)
        internal
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(signature.length == 65, "NFT.com: !65 length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return (v, r, s);
    }
}