// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract SignatureCheck {

    bytes32 public immutable DOMAIN_SEPARATOR;

    constructor(string memory name_, string memory version){
        uint256 chainId;
        assembly {chainId := chainid()}
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name_)),
                keccak256(bytes(version)),
                chainId,
                address(this)));
    }

    function verifySignature(address owner, bytes32 hashStruct, uint8 v, bytes32 r, bytes32 s) internal view returns (bool){
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                hashStruct));
        address signer = ecrecover(hash, v, r, s);
        return (signer != address(0) && signer == owner);
    }
}