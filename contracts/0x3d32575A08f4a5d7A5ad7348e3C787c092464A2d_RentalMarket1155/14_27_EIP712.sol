// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {LendOrder, RentalPrice, RentOffer} from "../constant/RentalStructs.sol";
import {NFT, Fee, SignatureVersion, Signature, Metadata} from "../constant/BaseStructs.sol";
import {SignatureVerificationErrors} from "./SignatureVerificationErrors.sol";
import {EIP1271Interface} from "./EIP1271Interface.sol";

/**
 * @title EIP712
 * @dev Contains all of the order hashing functions for EIP712 compliant signatures
 */
contract EIP712 is SignatureVerificationErrors {
    // Signature-related
    bytes32 internal constant EIP2098_allButHighestBitMask = (
        0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
    );
    bytes32 internal constant NFT_TYPEHASH =
        keccak256(
            "NFT(uint8 tokenType,address token,uint256 tokenId,uint256 amount)"
        );
    bytes32 internal constant RENTAL_PRICE_TYPEHASH =
        keccak256(
            "RentalPrice(address paymentToken,uint256 pricePerCycle,uint256 cycle)"
        );

    bytes32 internal constant FEE_TYPEHASH =
        keccak256("Fee(uint16 rate,address recipient)");

    bytes32 internal constant METADATA_TYPEHASH =
        keccak256("Metadata(bytes32 metadataHash,address checker)");

    bytes32 internal constant LEND_ORDER_TYPEHASH =
        keccak256(
            "LendOrder(address maker,address taker,NFT nft,RentalPrice price,uint256 minCycleAmount,uint256 maxRentExpiry,uint256 nonce,uint256 salt,uint64 durationId,Fee[] fees,Metadata metadata)Fee(uint16 rate,address recipient)Metadata(bytes32 metadataHash,address checker)NFT(uint8 tokenType,address token,uint256 tokenId,uint256 amount)RentalPrice(address paymentToken,uint256 pricePerCycle,uint256 cycle)"
        );
    bytes32 internal constant RENT_OFFER_TYPEHASH =
        keccak256(
            "RentOffer(address maker,address taker,NFT nft,RentalPrice price,uint256 cycleAmount,uint256 offerExpiry,uint256 nonce,uint256 salt,Fee[] fees,Metadata metadata)Fee(uint16 rate,address recipient)Metadata(bytes32 metadataHash,address checker)NFT(uint8 tokenType,address token,uint256 tokenId,uint256 amount)RentalPrice(address paymentToken,uint256 pricePerCycle,uint256 cycle)"
        );

    bytes32 internal constant DOMAIN =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    bytes32 internal constant NAME = keccak256("Double");
    bytes32 internal constant VERSION = keccak256("1.0.0");
    bytes32 DOMAIN_SEPARATOR;

    function _hashDomain() internal {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(DOMAIN, NAME, VERSION, block.chainid, address(this))
        );
    }

    function _getEIP712Hash(bytes32 structHash) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(hex"1901", DOMAIN_SEPARATOR, structHash)
            );
    }

    function _hashStruct_NFT(NFT calldata nft) internal pure returns (bytes32) {
        return keccak256(abi.encode(NFT_TYPEHASH, nft));
    }

    function _hashStruct_Metadata(
        Metadata calldata metadata
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(METADATA_TYPEHASH, metadata));
    }

    function _hashStruct_RentalPrice(
        RentalPrice calldata price
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(RENTAL_PRICE_TYPEHASH, price));
    }

    function _hashFee(Fee calldata fee) internal pure returns (bytes32) {
        return keccak256(abi.encode(FEE_TYPEHASH, fee.rate, fee.recipient));
    }

    function _packFees(Fee[] calldata fees) internal pure returns (bytes32) {
        bytes32[] memory feeHashes = new bytes32[](fees.length);
        for (uint256 i = 0; i < fees.length; i++) {
            feeHashes[i] = _hashFee(fees[i]);
        }
        return keccak256(abi.encodePacked(feeHashes));
    }

    function _hashStruct_LendOrder(
        LendOrder calldata order
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    LEND_ORDER_TYPEHASH,
                    order.maker,
                    order.taker,
                    _hashStruct_NFT(order.nft),
                    _hashStruct_RentalPrice(order.price),
                    order.minCycleAmount,
                    order.maxRentExpiry,
                    order.nonce,
                    order.salt,
                    order.durationId,
                    _packFees(order.fees),
                    _hashStruct_Metadata(order.metadata)
                )
            );
    }

    function _hashStruct_RentOffer(
        RentOffer calldata rentOffer
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    RENT_OFFER_TYPEHASH,
                    rentOffer.maker,
                    rentOffer.taker,
                    _hashStruct_NFT(rentOffer.nft),
                    _hashStruct_RentalPrice(rentOffer.price),
                    rentOffer.cycleAmount,
                    rentOffer.offerExpiry,
                    rentOffer.nonce,
                    rentOffer.salt,
                    _packFees(rentOffer.fees),
                    _hashStruct_Metadata(rentOffer.metadata)
                )
            );
    }

    function _validateSignature(
        address signer,
        bytes32 orderHash,
        Signature memory signature
    ) internal view {
        bytes32 hashToSign = _getEIP712Hash(orderHash);
        _assertValidSignature(signer, hashToSign, signature.signature);
    }

    /**
     * @dev Internal view function to verify the signature of an order. An
     *      ERC-1271 fallback will be attempted if either the signature length
     *      is not 64 or 65 bytes or if the recovered signer does not match the
     *      supplied signer. Note that in cases where a 64 or 65 byte signature
     *      is supplied, only standard ECDSA signatures that recover to a
     *      non-zero address are supported.
     *
     * @param signer    The signer for the order.
     * @param digest    The digest to verify the signature against.
     * @param signature A signature from the signer indicating that the order
     *                  has been approved.
     */
    function _assertValidSignature(
        address signer,
        bytes32 digest,
        bytes memory signature
    ) internal view {
        // Declare r, s, and v signature parameters.
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signer.code.length > 0) {
            // If signer is a contract, try verification via EIP-1271.
            _assertValidEIP1271Signature(signer, digest, signature);

            // Return early if the ERC-1271 signature check succeeded.
            return;
        } else if (signature.length == 64) {
            // If signature contains 64 bytes, parse as EIP-2098 signature. (r+s&v)
            // Declare temporary vs that will be decomposed into s and v.
            bytes32 vs;

            (r, vs) = abi.decode(signature, (bytes32, bytes32));

            s = vs & EIP2098_allButHighestBitMask;

            v = SafeCast.toUint8(uint256(vs >> 255)) + 27;
        } else if (signature.length == 65) {
            (r, s) = abi.decode(signature, (bytes32, bytes32));
            v = uint8(signature[64]);

            // Ensure v value is properly formatted.
            if (v != 27 && v != 28) {
                revert BadSignatureV(v);
            }
        } else {
            revert InvalidSignature();
        }

        // Attempt to recover signer using the digest and signature parameters.
        address recoveredSigner = ecrecover(digest, v, r, s);

        // Disallow invalid signers.
        if (recoveredSigner == address(0) || recoveredSigner != signer) {
            revert InvalidSigner();
            // Should a signer be recovered, but it doesn't match the signer...
        }
    }

    /**
     * @dev Internal view function to verify the signature of an order using
     *      ERC-1271 (i.e. contract signatures via `isValidSignature`).
     *
     * @param signer    The signer for the order.
     * @param digest    The signature digest, derived from the domain separator
     *                  and the order hash.
     * @param signature A signature (or other data) used to validate the digest.
     */
    function _assertValidEIP1271Signature(
        address signer,
        bytes32 digest,
        bytes memory signature
    ) internal view {
        if (
            EIP1271Interface(signer).isValidSignature(digest, signature) !=
            EIP1271Interface.isValidSignature.selector
        ) {
            revert InvalidSigner();
        }
    }

}