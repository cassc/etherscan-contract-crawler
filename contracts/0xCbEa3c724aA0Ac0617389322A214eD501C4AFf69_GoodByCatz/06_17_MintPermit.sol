//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

struct MintPermitStruct {
    uint256 userId;
    address recipient;
    uint256 tokenId;
    uint256 price;
    uint256 deadline;
}

contract MintPermit is Ownable {
    using ECDSA for bytes32;

    address private SIGNING_KEY = address(0);

    bytes32 public DOMAIN_SEPARATOR;

    bytes32 public constant MINTER_TYPEHASH =
        keccak256(
            "MintPermit(uint256 userId,address recipient,uint256 tokenId,uint256 price,uint256 deadline)"
        );

    constructor(address signingWallet) {
        SIGNING_KEY = signingWallet;

        bytes32 hashedName = keccak256(bytes("GoodByeCatz"));
        bytes32 hashedVersion = keccak256(bytes("1"));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

        DOMAIN_SEPARATOR = _buildDomainSeparatorV4(
            typeHash,
            hashedName,
            hashedVersion
        );
    }

    function _buildDomainSeparatorV4(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    typeHash,
                    nameHash,
                    versionHash,
                    block.chainid,
                    address(this)
                )
            );
    }

    function setWhitelistSigningAddress(address newSigningKey)
        public
        onlyOwner
    {
        SIGNING_KEY = newSigningKey;
    }

    function _hashTypedDataV4(MintPermitStruct memory mintPermit)
        internal
        view
        virtual
        returns (bytes32)
    {
        bytes32 structHash = keccak256(
            abi.encode(
                MINTER_TYPEHASH,
                mintPermit.userId,
                mintPermit.recipient,
                mintPermit.tokenId,
                mintPermit.price,
                mintPermit.deadline
            )
        );

        return ECDSA.toTypedDataHash(DOMAIN_SEPARATOR, structHash);
    }

    modifier requiresMintPermit(
        MintPermitStruct memory mintPermit,
        bytes calldata signature
    ) {
        require(
            block.timestamp <= mintPermit.deadline,
            "MintPermit: expired deadline"
        );

        require(SIGNING_KEY != address(0), "MintPermit: SIGNING_KEY not set");

        bytes32 digest = _hashTypedDataV4(mintPermit);

        bool isValid = SignatureChecker.isValidSignatureNow(
            SIGNING_KEY,
            digest,
            signature
        );
        require(isValid, "MintPermit: Invalid Signature");
        _;
    }
}