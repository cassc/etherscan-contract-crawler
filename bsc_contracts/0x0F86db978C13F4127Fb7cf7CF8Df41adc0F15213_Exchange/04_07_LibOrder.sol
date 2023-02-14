pragma solidity ^0.8.10;

// SPDX-License-Identifier: UNLICENSED

library LibOrder {
    //keccak256("Order(address user,address sellToken,address buyToken,uint256 sellAmount,uint256 buyAmount,uint256 expirationTimeSeconds, uint nonce)")
    bytes32 internal constant _EIP712_ORDER_SCHEMA_HASH = 0xfee94c0fa16356fd77c9559019fab290583d7f33d3dc2d47ce92012467cca44e;
    
    enum Status {
        PENDING,
        PARTIALCOMPLETED,
        COMPLETED,
        CANCLED
    }

    struct Order {
        address maker;
        bytes32[] takerOrderHashs; 
        address[2] tokens; 
        uint[2] amounts;
        uint[2] pAmounts;
        uint fee; 
        uint createdAt;
        uint executedAt;
        Status status;
    }

    struct OrderInfo {
        bytes32[] orderQueqe; 
        uint256 lastIndex; 
    }
    
    function getOrderHash(address user, address sellToken ,address buyToken,uint256 sellAmount,uint256 buyAmount, uint256 createdAt, uint nonce) internal pure returns (bytes32 orderHash) {
        orderHash = keccak256(abi.encode(_EIP712_ORDER_SCHEMA_HASH, user, sellToken, buyToken, sellAmount, buyAmount, createdAt,nonce));   
    }

}