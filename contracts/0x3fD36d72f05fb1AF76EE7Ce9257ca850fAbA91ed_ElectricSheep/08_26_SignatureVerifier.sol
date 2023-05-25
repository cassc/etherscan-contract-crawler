// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract SignatureVerifier is Ownable, EIP712 {
    using ECDSA for bytes32;

    error InvalidSignature();
    error VerificationKeyNotSet();

    struct VerificationKey {
        address allowlist;
        address publicSale;
        address builderMint;
    }

    VerificationKey public verificationKey;
    bytes32 public constant ALLOWLIST_TYPEHASH = keccak256("Allowlist(address wallet,uint256 quota)");
    bytes32 public constant PUBLIC_SALE_TYPEHASH = keccak256("PubSale(address wallet,uint256 quantity)");
    bytes32 public constant BUILDER_MINT_TYPEHASH = keccak256("BuilderMint(address wallet,uint256 quota)");

    /**
     * @notice Constructor
     * @param name eip712 domain name
     * @param version eip712 domain version
     */
    constructor(string memory name, string memory version) EIP712(name, version) {}

    modifier verifyAllowlist(uint256 quota, bytes calldata signature) {
        if (verificationKey.allowlist == address(0)) {
            revert VerificationKeyNotSet();
        }
        if (getAllowlistRecoverAddress(quota, signature) != verificationKey.allowlist) {
            revert InvalidSignature();
        }
        _;
    }

    modifier verifyPublicSale(uint256 quantity, bytes calldata signature) {
        if (verificationKey.publicSale == address(0)) {
            revert VerificationKeyNotSet();
        }
        if (getPublicSaleRecoverAddress(quantity, signature) != verificationKey.publicSale) {
            revert InvalidSignature();
        }
        _;
    }

    modifier verifyBuilderMint(uint256 quota, bytes calldata signature) {
        if (verificationKey.builderMint == address(0)) {
            revert VerificationKeyNotSet();
        }
        if (getBuilderMintRecoverAddress(quota, signature) != verificationKey.builderMint) {
            revert InvalidSignature();
        }
        _;
    }

    /**
     * @notice Set signature verify address for every sale phases
     * @param keyForAllowlist allowlist signature address
     * @param keyForPublicSale publicSale signature address
     * @param keyForBuilderMint builderMint signature address
     */
    function setSignatureVerificationKey(
        address keyForAllowlist,
        address keyForPublicSale,
        address keyForBuilderMint
    ) external onlyOwner {
        verificationKey.allowlist = keyForAllowlist;
        verificationKey.publicSale = keyForPublicSale;
        verificationKey.builderMint = keyForBuilderMint;
    }

    function getAllowlistRecoverAddress(uint256 quota, bytes calldata signature) internal view returns (address) {
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(ALLOWLIST_TYPEHASH, _msgSender(), quota)));
        return ECDSA.recover(digest, signature);
    }

    function getPublicSaleRecoverAddress(uint256 quantity, bytes calldata signature) internal view returns (address) {
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(PUBLIC_SALE_TYPEHASH, _msgSender(), quantity)));
        return ECDSA.recover(digest, signature);
    }

    function getBuilderMintRecoverAddress(uint256 quantity, bytes calldata signature) internal view returns (address) {
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(BUILDER_MINT_TYPEHASH, _msgSender(), quantity)));
        return ECDSA.recover(digest, signature);
    }
}