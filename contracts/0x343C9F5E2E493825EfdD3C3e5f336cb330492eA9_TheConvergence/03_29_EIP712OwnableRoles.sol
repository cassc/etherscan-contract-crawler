// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "solady/src/utils/ECDSA.sol";
import "../utils/errors.sol";
import "solady/src/auth/OwnableRoles.sol";

abstract contract EIP712OwnableRoles is OwnableRoles {
    using ECDSA for bytes32;

    // The key used to sign allowlist signatures.
    // We will check to ensure that the key that signed the signature
    // is this one that we expect.
    address private _allowlistSignerAddress;

    // Domain Separator is the EIP-712 defined structure that defines what contract
    // and chain these signatures can be used for.  This ensures people can't take
    // a signature used to mint on one contract and use it for another, or a signature
    // from testnet to replay on mainnet.
    // It has to be created in the constructor so we can dynamically grab the chainId.
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#definition-of-domainseparator
    bytes32 private immutable _DOMAIN_SEPARATOR;

    // The typehash for the data type specified in the structured data
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#rationale-for-typehash
    // This should match whats in the client side allowlist signing code
    // https://github.com/msfeldstein/EIP712-allowlisting/blob/main/test/signAllowlist.ts#L22
    bytes32 private constant _MINTER_TYPEHASH = keccak256("Minter(address wallet)");

    constructor(string memory domainVerifierAppName_,
                string memory domainVerifierAppVersion_,
                address allowlistSignerAddress_ ) {
        // This should match whats in the client side allowlist signing code
        // https://github.com/msfeldstein/EIP712-allowlisting/blob/main/test/signAllowlist.ts#L12
        _DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                // This should match the domain you set in your client side signing.
                keccak256(bytes(domainVerifierAppName_)), // "AllowlistToken"
                keccak256(bytes(domainVerifierAppVersion_)), // "1"
                block.chainid,
                address(this)
            )
        );

        _allowlistSignerAddress = allowlistSignerAddress_;
    }

    function setAllowlistSigningAddress(address newSigningAddress) public onlyOwner {
        _allowlistSignerAddress = newSigningAddress;
    }

    modifier requiresAllowlist(bytes calldata signature) {
        // Verify EIP-712 signature by recreating the data structure
        // that we signed on the client side, and then using that to recover
        // the address that signed the signature for this data.
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _DOMAIN_SEPARATOR,
                keccak256(abi.encode(_MINTER_TYPEHASH, msg.sender))
            )
        );
        // Use the recover method to see what address was used to create
        // the signature on this data.
        // Note that if the digest doesn't exactly match what was signed we'll
        // get a random recovered address.
        if(digest.recover(signature) != _allowlistSignerAddress) { revert InvalidSignature();}
        _;
    }
}