// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

library Registration {
    // keccak256("RegisterOrder(address issuer,address registrar,address owner,address resolver,address currency,uint256 duration,uint256 applyingTime,bytes name,bytes params)")
    bytes32 public constant REGISTER_ORDER_HASH =
        keccak256(
            "RegisterOrder(address issuer,address registrar,address owner,address resolver,address currency,uint256 duration,uint256 applyingTime,bytes name,bytes params)"
        );

    struct RegisterOrder {
        address issuer; // name issuer address (signer)
        address registrar; // TLD registrar
        address owner; // name owner address
        address resolver; // name resolver, used to resolve name information
        address currency; // register payment token (e.g., WETH)
        uint256 duration; // name validity period
        uint256 applyingTime; // name registration needs to wait for a period of time(minCommitmentAge) after the applying time
        bytes name; // name being registered
        bytes params; // additional parameters
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s; // s: parameter
    }

    function hash(RegisterOrder memory registerOrder)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    REGISTER_ORDER_HASH,
                    registerOrder.issuer,
                    registerOrder.registrar,
                    registerOrder.owner,
                    registerOrder.resolver,
                    registerOrder.currency,
                    registerOrder.duration,
                    registerOrder.applyingTime,
                    keccak256(registerOrder.name),
                    keccak256(registerOrder.params)
                )
            );
    }
}