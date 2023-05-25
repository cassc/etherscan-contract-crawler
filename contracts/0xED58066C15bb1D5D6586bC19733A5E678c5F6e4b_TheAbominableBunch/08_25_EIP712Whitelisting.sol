//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EIP712Whitelisting is Ownable {
    using ECDSA for bytes32;

    // The key used to sign whitelist signatures.
    // We will check to ensure that the key that signed the signature
    // is this one that we expect.
    address private whitelistSigningKey = address(0);

    // Domain Separator is the EIP-712 defined structure that defines what contract
    // and chain these signatures can be used for.  This ensures people can't take
    // a signature used to mint on one contract and use it for another, or a signature
    // from testnet to replay on mainnet.
    // It has to be created in the constructor so we can dynamically grab the chainId.
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#definition-of-domainseparator
    bytes32 internal DOMAIN_SEPARATOR;

    // The typehash for the data type specified in the structured data
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#rationale-for-typehash
    bytes32 internal constant MINTER_TYPEHASH = keccak256("Minter(address wallet,int max)");

    constructor(string memory _name) {
        // This should match whats in the client side whitelist signing code
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(_name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    function setWhitelistSigningAddress(address newSigningKey) external onlyOwner {
        whitelistSigningKey = newSigningKey;
    }

    function checkWhitelist(uint256 max, bytes calldata signature) internal view returns (bool) {
        require(whitelistSigningKey != address(0), "Whitelist account not configured");

        // Verify EIP-712 signature by recreating the data structure
        // that we signed on the client side, and then using that to recover
        // the address that signed the signature for this data.
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, keccak256(abi.encode(MINTER_TYPEHASH, msg.sender, max))));

        // Use the recover method to see what address was used to create
        // the signature on this data.
        // Note: that if the digest doesn't exactly match what was signed we'll
        // get a random recovered address.
        return digest.recover(signature) == whitelistSigningKey;
    }
}