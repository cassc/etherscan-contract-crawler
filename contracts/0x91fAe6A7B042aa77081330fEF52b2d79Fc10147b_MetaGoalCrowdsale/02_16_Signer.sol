//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Signer is Ownable {
    using ECDSA for bytes32;

    // The key used to sign whitelist signatures.
    // We will check to ensure that the key that signed the signature
    // is this one that we expect.
    address signingKey = address(0);

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
    bytes32 public constant GIFT_TYPEHASH =
        keccak256("Gift(address wallet,uint256 nonce)");

    mapping(uint256 => address) cardOwners;

    constructor(string memory name) {
        // This should match whats in the client side whitelist signing code
        // https://github.com/msfeldstein/EIP712-whitelisting/blob/main/test/signWhitelist.ts#L12
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                // This should match the domain you set in your client side signing.
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    function checkCardId(uint256 cardId) public view returns (address) {
        return cardOwners[cardId];
    }

    function setSigningKey(address newSigningKey) public onlyOwner {
        signingKey = newSigningKey;
    }

    modifier requiresSignature(bytes calldata signature,uint256 cardId) {
        require(signingKey != address(0), "Signing not enabled");
        require(cardOwners[cardId] == address(0),"cardId exist");
        address recoveredAddress = recoverSigner(
            msg.sender,
            GIFT_TYPEHASH,
            signature,
            cardId
        );
        require(recoveredAddress == signingKey, "Invalid Signature");
        _;
        cardOwners[cardId] = msg.sender;
        //nonces[msg.sender] = nonces[msg.sender] + 1;
    }

    function restorable(address sender, bytes calldata signature,uint256 cardId)
        public
        view
        returns (bool)
    {
        return signingKey == recoverSigner(sender, GIFT_TYPEHASH, signature,cardId);
    }

    function recoverSigner(
        address sender,
        bytes32 typehash,
        bytes calldata signature,
        uint256 cardId
    ) internal view returns (address) {
        // Verify EIP-712 signature by recreating the data structure
        // that we signed on the client side, and then using that to recover
        // the address that signed the signature for this data.
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(typehash, sender, cardId))
            )
        );
        // Use the recover method to see what address was used to create
        // the signature on this data.
        // Note that if the digest doesn't exactly match what was signed we'll
        // get a random recovered address.
        return digest.recover(signature);
    }
}