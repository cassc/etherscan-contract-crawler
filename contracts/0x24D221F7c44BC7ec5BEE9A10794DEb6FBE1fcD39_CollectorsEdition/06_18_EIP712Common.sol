//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Ownable.sol";

error InvalidSignature();
error NoSigningKey();

contract EIP712Common is Ownable {
    using ECDSA for bytes32;

    // The key used to sign whitelist signatures.
    address signingKey = address(0);

    // Domain Separator is the EIP-712 defined structure that defines what contract
    // and chain these signatures can be used for.  This ensures people can't take
    // a signature used to mint on one contract and use it for another, or a signature
    // from testnet to replay on mainnet.
    // It has to be created in the constructor so we can dynamically grab the chainId.
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#definition-of-domainseparator
    bytes32 public CLAIM_DOMAIN_SEPARATOR;
    bytes32 public WHITELIST_DOMAIN_SEPARATOR;
    bytes32 public DISCOUNT_DOMAIN_SEPARATOR;

    // The typehash for the data type specified in the structured data
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#rationale-for-typehash
    // This should match whats in the client side whitelist signing code
    // https://github.com/msfeldstein/EIP712-whitelisting/blob/main/test/signWhitelist.ts#L22
    bytes32 public constant CLAIM_TYPEHASH =
        keccak256("Minter(address wallet,uint256 count)");

    bytes32 public constant WHITELIST_TYPEHASH =
        keccak256("Minter(address wallet)");

    bytes32 public constant DISCOUNT_TYPEHASH =
        keccak256("Minter(address wallet,uint256 count)");

    constructor() {
        CLAIM_DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("ClaimToken")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );

        WHITELIST_DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("WhitelistToken")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );

        DISCOUNT_DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("DiscountToken")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    function setSigningAddress(address newSigningKey) public onlyOwner {
        signingKey = newSigningKey;
    }

    modifier requiresClaim(bytes calldata signature, uint256 count) {
        if (signingKey == address(0)) revert NoSigningKey();

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                CLAIM_DOMAIN_SEPARATOR,
                keccak256(abi.encode(CLAIM_TYPEHASH, msg.sender, count))
            )
        );

        address recoveredAddress = digest.recover(signature);
        if (recoveredAddress != signingKey) revert InvalidSignature();
        _;
    }

    modifier requiresDiscount(bytes calldata signature, uint256 value) {
        if (signingKey == address(0)) revert NoSigningKey();

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DISCOUNT_DOMAIN_SEPARATOR,
                keccak256(abi.encode(CLAIM_TYPEHASH, msg.sender, value))
            )
        );

        address recoveredAddress = digest.recover(signature);
        if (recoveredAddress != signingKey) revert InvalidSignature();
        _;
    }

    modifier requiresWhitelist(bytes calldata signature) {
        if (signingKey == address(0)) revert NoSigningKey();

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                WHITELIST_DOMAIN_SEPARATOR,
                keccak256(abi.encode(WHITELIST_TYPEHASH, msg.sender))
            )
        );

        address recoveredAddress = digest.recover(signature);
        if (recoveredAddress != signingKey) revert InvalidSignature();
        _;
    }
}