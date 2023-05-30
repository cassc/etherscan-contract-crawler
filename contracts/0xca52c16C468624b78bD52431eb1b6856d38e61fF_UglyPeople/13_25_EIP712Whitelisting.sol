// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EIP712Whitelisting is Ownable {
    using ECDSA for bytes32;

    event AssignWhitelistSigningAddress(address indexed _address);
    event AssignOgSigningAddress(address indexed _address);

    // The key used to sign whitelist signatures.
    // We will check to ensure that the key that signed the signature
    // is this one that we expect.
    address whitelistSigningKey = address(0);

    address ogSigningKey = address(0);

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
    bytes32 public constant MINTER_TYPEHASH =
        keccak256("Minter(address wallet)");

    constructor(string memory _schemeName) {
        // This should match whats in the client side whitelist signing code
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                // This should match the domain you set in your client side signing.
                keccak256(bytes.concat(bytes(_schemeName), bytes("Whitelist"))),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    function setWhitelistSigningAddress(address newSigningKey)
        external
        onlyOwner
    {
        whitelistSigningKey = newSigningKey;
        emit AssignWhitelistSigningAddress(newSigningKey);
    }

    function setOgSigningAddress(address newSigningKey) external onlyOwner {
        ogSigningKey = newSigningKey;
        emit AssignOgSigningAddress(newSigningKey);
    }

    modifier requiresWhitelist(bytes calldata signature) {
        require(whitelistSigningKey != address(0), "whitelist not enabled.");
        require(
            getEIP712RecoverAddress(signature) == whitelistSigningKey,
            "Not whitelisted."
        );
        _;
    }

    modifier requiresOg(bytes calldata signature) {
        require(ogSigningKey != address(0), "og not enabled.");
        require(getEIP712RecoverAddress(signature) == ogSigningKey, "Not OG.");
        _;
    }

    function isEIP712WhiteListed(bytes calldata signature)
        public
        view
        returns (bool)
    {
        require(whitelistSigningKey != address(0), "whitelist not enabled.");
        return getEIP712RecoverAddress(signature) == whitelistSigningKey;
    }

    function isOGwhitelisted(bytes calldata signature)
        public
        view
        returns (bool)
    {
        require(ogSigningKey != address(0), "og not enabled.");
        return getEIP712RecoverAddress(signature) == ogSigningKey;
    }

    function getEIP712RecoverAddress(bytes calldata signature)
        internal
        view
        returns (address)
    {
        // Verify EIP-712 signature by recreating the data structure
        // that we signed on the client side, and then using that to recover
        // the address that signed the signature for this data.
        // Signature begin with \x19\x01, see: https://eips.ethereum.org/EIPS/eip-712
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(MINTER_TYPEHASH, msg.sender))
            )
        );

        // Use the recover method to see what address was used to create
        // the signature on this data.
        // Note that if the digest doesn't exactly match what was signed we'll
        // get a random recovered address.
        return digest.recover(signature);
    }
}