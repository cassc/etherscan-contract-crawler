// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

import {ISignature} from "./interface/ISignature.sol";

import {NFToken} from "./DataStructure/Objects.sol";
import {Offer, ApiCoSignedPayload} from "./DataStructure/Objects.sol";

/// @notice handles signature verification
abstract contract Signature is ISignature, EIP712 {
    bytes32 internal constant OFFER_TYPEHASH =
        keccak256(
            "Offer(address assetToLend,uint256 loanToValue,uint256 duration,"
            "uint256 expirationDate,uint256 tranche,bytes32 nftListMerkleRoot)"
        ); // strings based on ethers js output
    bytes32 internal constant API_CO_SIGNED_PAYLOAD_TYPEHASH =
        keccak256("ApiCoSignedPayload(uint256 inclusionLimitDate,bytes lenderSignature)");

    /* solhint-disable-next-line no-empty-blocks */
    constructor() EIP712("Kairos Loan protocol", "1.0") {}

    /// @notice computes EIP-712 compliant digest of a loan offer
    /// @param offer the loan offer signed/to sign by a supplier
    /// @return digest the digest, ecdsa sign as is to produce a valid loan offer signature
    function offerDigest(Offer memory offer) public view returns (bytes32) {
        return _hashTypedDataV4(typeHashOffer(offer));
    }

    /// @notice computes EIP-712 hashStruct of an api co-signed payload
    /// @param apiPayload - to sign/signed by the api
    /// @return digest the digest, ecdsa sign as is to produce a valid api co validation
    function apiCoSignedPayloadDigest(ApiCoSignedPayload memory apiPayload) public view returns (bytes32) {
        return _hashTypedDataV4(typeHashApiCoSignedPayload(apiPayload));
    }

    /// @notice computes EIP-712 hashStruct of an api co-signed payload
    /// @param apiPayload - to get the hash from
    /// @return typehash of the api co-signed payload
    function typeHashApiCoSignedPayload(ApiCoSignedPayload memory apiPayload) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    API_CO_SIGNED_PAYLOAD_TYPEHASH,
                    apiPayload.inclusionLimitDate,
                    keccak256(abi.encodePacked(apiPayload.lenderSignature))
                )
            );
    }

    /// @notice computes EIP-712 hashStruct of an offer
    /// @param offer the loan offer to hash
    /// @return the hashStruct
    function typeHashOffer(Offer memory offer) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    OFFER_TYPEHASH,
                    offer.assetToLend,
                    offer.loanToValue,
                    offer.duration,
                    offer.expirationDate,
                    offer.tranche,
                    offer.nftListMerkleRoot
                )
            );
    }
}