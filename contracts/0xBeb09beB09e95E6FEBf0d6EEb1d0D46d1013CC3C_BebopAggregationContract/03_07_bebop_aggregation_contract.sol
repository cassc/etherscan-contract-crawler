// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

enum SignatureType {
    EIP712,  //0
    EIP1271, //1
    ETHSIGN  //2
}

struct Signature {
    SignatureType signatureType;
    bytes signatureBytes;
}

struct AggregateOrder {
    uint256 expiry;
    address taker_address;
    address[] maker_addresses;
    uint256[] maker_nonces;
    address[][] taker_tokens;
    address[][] maker_tokens;
    uint256[][] taker_amounts;
    uint256[][] maker_amounts;
    address receiver;
}

struct PartialOrder {
    uint256 expiry;
    address taker_address;
    address maker_address;
    uint256 maker_nonce;
    address[] taker_tokens;
    address[] maker_tokens;
    uint256[] taker_amounts;
    uint256[] maker_amounts;
    address receiver;
}

interface IBebopAggregationContract {
    event AggregateOrderExecuted(
        bytes32 order_hash
    );

    event OrderSignerRegistered(address maker, address signer, bool allowed);

    function hashAggregateOrder(AggregateOrder memory order) external view returns (bytes32);
    function hashPartialOrder(PartialOrder memory order) external view returns (bytes32);
    function registerAllowedOrderSigner(address signer, bool allowed) external;

    function validateMakerSignature(
        address maker_address,
        bytes32 hash,
        Signature memory signature
    ) external view;

    function SettleAggregateOrder(
        AggregateOrder memory order,
        bytes memory takerSig,
        Signature[] memory makerSigs
    ) external payable returns (bool);

}