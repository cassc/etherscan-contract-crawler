// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title OrderTypes
 * @notice This library contains order types for the etch.market ethscription exchange.
 */
library OrderTypes {
    bytes32 internal constant ETHSCRIPTION_ORDER_HASH =
        keccak256(
            "EthscriptionOrder(address signer,address creator,bytes32 ethscriptionId,uint256 quantity,address currency,uint256 price,uint256 nonce,uint64 startTime,uint64 endTime,uint16 protocolFeeDiscounted,uint16 creatorFee,bytes params)"
        );

    struct EthscriptionOrder {
        address signer; // signer of the ethscription seller
        address creator; // deployer of the ethscription collection
        bytes32 ethscriptionId; // ethscription id
        uint256 quantity; // if the ethscription is nft: 1, else if is ft: >= 1
        address currency; // currency (e.g., ETH)
        uint256 price; // price
        uint256 nonce; // order nonce (must be unique unless new maker order is meant to override existing one e.g., lower ask price)
        uint64 startTime; // startTime in timestamp
        uint64 endTime; // endTime in timestamp
        uint16 protocolFeeDiscounted; // with some rights and interests, the protocol fee can be discounted, default: 0
        uint16 creatorFee;
        bytes params; // additional parameters
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s; // s: parameter
    }

    function hash(EthscriptionOrder memory order) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ETHSCRIPTION_ORDER_HASH,
                    order.signer,
                    order.creator,
                    order.ethscriptionId,
                    order.quantity,
                    order.currency,
                    order.price,
                    order.nonce,
                    order.startTime,
                    order.endTime,
                    order.protocolFeeDiscounted,
                    order.creatorFee,
                    keccak256(order.params)
                )
            );
    }
}