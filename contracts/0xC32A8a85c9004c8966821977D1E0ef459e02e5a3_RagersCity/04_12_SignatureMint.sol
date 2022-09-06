//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// @title:  Ragers City
// @desc:   Ragers City is a next-gen decentralized Manga owned by the community, featuring a collection of 5000 NFTs.
// @team:   https://twitter.com/RagersCity
// @author: https://linkedin.com/in/antoine-andrieux
// @url:    https://ragerscity.com

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract SignatureMint is Ownable {
    using ECDSA for bytes32;

    // The key used to sign the whitelist signatures.
    // We will check that the key that signed the signature
    // is the one we expect.
    address whitelistSigningKey = address(0);

    // The domain separator is the structure defined by the EIP-712 that defines the contract
    // and the string for which these signatures can be used.  This ensures that people cannot take
    // a signature used to hit one contract and use it for another, or a signature from the testnet to be replayed on the mainnet.
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#definition-of-domainseparator
    bytes32 public immutable DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("SignatureMint")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
        

    // The typehash for the data type specified in the structured data, which 
    // corresponds to the blanks in the client-side whitelist signature code.
    bytes32 public constant MINTER_TYPEHASH =
        keccak256("Minter(address wallet,bool hasFreeMint)");


    event WhitelistSigningKeyChanged(address newSigningKey);


    function setWhitelistSigningAddress(address newSigningKey) public onlyOwner {
        whitelistSigningKey = newSigningKey;
        emit WhitelistSigningKeyChanged(whitelistSigningKey);
    }

    modifier requiresWhitelist(bytes calldata signature, bool _hasFreeMint) {
        require(whitelistSigningKey != address(0), "whitelist not enabled");
        // Verify EIP-712 signature by recreating the data structure
        // that we signed on the client side, and then using that to recover
        // the address that signed the signature for this data.
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(MINTER_TYPEHASH, msg.sender, _hasFreeMint))
            )
        );
        // Use the recover method to see what address was used to create
        // the signature on this data.
        // Note that if the digest doesn't exactly match what was signed we'll
        // get a random recovered address.
        address recoveredAddress = digest.recover(signature);
        require(recoveredAddress == whitelistSigningKey, "Invalid Signature");
        _;
    }

    function isFree(bytes calldata signature, bool _hasFreeMint) public view returns(bool) {
        require(whitelistSigningKey != address(0), "Free whitelist not enabled");
        // Verify EIP-712 signature by recreating the data structure
        // that we signed on the client side, and then using that to recover
        // the address that signed the signature for this data.
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(MINTER_TYPEHASH, msg.sender, _hasFreeMint))
            )
        );
        // Use the recover method to see what address was used to create
        // the signature on this data.
        // Note that if the digest doesn't exactly match what was signed we'll
        // get a random recovered address.
        address recoveredAddress = digest.recover(signature);
        return recoveredAddress == whitelistSigningKey;
    }
}