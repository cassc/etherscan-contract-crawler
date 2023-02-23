// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;


library OrderEIP712 {

    bytes32 constant ORDER_TYPEHASH_V1 = keccak256("Order(uint256 nonce,address signer,address collection,uint256 price,uint256 maxGasPrice,uint16 maxNumberOfDeals,uint256 expiration,bytes4 assetClass,uint8 swapType)");
    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    enum SwapType {
        ANY,
        P2P,
        EXTERNAL
    }

    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    struct Order {
        uint256 nonce;
        address signer;
        address collection;
        uint256 price;
        uint256 maxGasPrice;
        uint16 maxNumberOfDeals;
        uint256 expiration;
        bytes4 assetClass;
        SwapType swapType;
    }

    struct OrderSig {
        uint256 nonce;
        address signer;
        address collection;
        uint256 price;
        uint256 maxGasPrice;
        uint16 maxNumberOfDeals;
        uint256 expiration;
        bytes4 assetClass;
        SwapType swapType;

        uint8 v;
        bytes32 r;
        bytes32 s;
    }
}