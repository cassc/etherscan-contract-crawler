// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

import {ISignature} from "./interface/ISignature.sol";

import {NFToken} from "./DataStructure/Objects.sol";
import {Offer} from "./DataStructure/Objects.sol";

/// @notice handles signature verification
abstract contract Signature is ISignature, EIP712 {
    bytes32 internal constant OFFER_TYPEHASH =
        keccak256(
            "Offer(address assetToLend,uint256 loanToValue,uint256 duration,"
            "uint256 expirationDate,uint256 tranche,NFToken collateral)"
            "NFToken(address implem,uint256 id)"
        ); // strings based on ethers js output
    bytes32 internal constant NFTOKEN_TYPEHASH = keccak256("NFToken(address implem,uint256 id)");

    /* solhint-disable-next-line no-empty-blocks */
    constructor() EIP712("Kairos Loan protocol", "0.1") {}

    /// @notice computes EIP-712 compliant digest of a loan offer
    /// @param offer the loan offer signed/to sign by a supplier
    /// @return digest the digest, ecdsa sign as is to produce a valid loan offer signature
    function offerDigest(Offer memory offer) public view returns (bytes32) {
        return _hashTypedDataV4(typeHashOffer(offer));
    }

    /// @notice computes EIP-712 hashStruct of an nfToken
    /// @param nft - to get the hash from
    /// @return the hashStruct
    function typeHashNFToken(NFToken memory nft) internal pure returns (bytes32) {
        return keccak256(abi.encode(NFTOKEN_TYPEHASH, nft));
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
                    typeHashNFToken(offer.collateral)
                )
            );
    }
}