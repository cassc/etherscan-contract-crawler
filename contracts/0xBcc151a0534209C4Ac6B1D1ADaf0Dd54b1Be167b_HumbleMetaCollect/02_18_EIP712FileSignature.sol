//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EIP712FileSignature is Ownable {
    using ECDSA for bytes32;

    // Domain Separator is the EIP-712 defined structure that defines what contract
    // and chain these signatures can be used for.  This ensures people can't take
    // a signature used to mint on one contract and use it for another, or a signature
    // from testnet to replay on mainnet.
    // It has to be created in the constructor so we can dynamically grab the chainId.
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#definition-of-domainseparator
    bytes32 public DOMAIN_SEPARATOR;

    // The typehash for the data type specified in the structured data
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#rationale-for-typehash
    // This should match whats in the client side whitelist signing code
    // https://github.com/msfeldstein/EIP712-whitelisting/blob/main/test/signWhitelist.ts#L22
    bytes32 public constant OWNER_TYPEHASH = keccak256("Owner(string name,string metadataHash,string dataId)");

    constructor() {
        // This should match whats in the client side whitelist signing code
        // https://github.com/msfeldstein/EIP712-whitelisting/blob/main/test/signWhitelist.ts#L12
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                // This should match the domain you set in your client side signing.
                keccak256(bytes("FileSignatureToken")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    modifier verifyFileSignature(bytes calldata signature, address signingKey, string memory signingName, string memory signingMetadataHash, string memory signingDataId) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        OWNER_TYPEHASH,
                        keccak256(bytes(signingName)),
                        keccak256(bytes(signingMetadataHash)),
                        keccak256(bytes(signingDataId))
                    )
                )
            )
        );
        
        address recoveredAddress = digest.recover(signature);
        require(recoveredAddress == signingKey, "Invalid signature");
        _;
    }
}