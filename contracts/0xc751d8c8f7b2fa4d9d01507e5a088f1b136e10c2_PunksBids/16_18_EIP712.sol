// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Bid} from "./BidStructs.sol";

/**
 * @title EIP712
 * @dev Contains all of the order hashing functions for EIP712 compliant signatures
 */
contract EIP712 {
    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    /* Order typehash for EIP 712 compatibility. */
    bytes32 internal constant BID_TYPEHASH = keccak256(
        "Bid(address bidder,bool attributesCountEnabled,uint8 attributesCount,uint16 modulo,uint16 maxIndex,uint16[] indexes,uint16[] excludedIndexes,string baseType,string attributes,uint256 amount,uint256 listingTime,uint256 expirationTime,uint256 salt,uint256 nonce)"
    );

    bytes32 internal constant EIP712DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    bytes32 internal _domainSeparator;

    /**
     * @dev Hash EIP712Domain
     * @param eip712Domain EIP712Domain struct
     * @return The hash of eip712Domain
     */
    function _hashDomain(EIP712Domain memory eip712Domain) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                EIP712DOMAIN_TYPEHASH,
                keccak256(bytes(eip712Domain.name)),
                keccak256(bytes(eip712Domain.version)),
                eip712Domain.chainId,
                eip712Domain.verifyingContract
            )
        );
    }

    /**
     * @dev Hash Bid
     * @param bid Bid struct
     * @return The hash of bid
     */
    function _hashBid(Bid memory bid, uint256 nonce) internal pure returns (bytes32) {
        return keccak256(
            bytes.concat(
                abi.encode(
                    BID_TYPEHASH,
                    bid.bidder,
                    bid.attributesCountEnabled,
                    bid.attributesCount,
                    bid.modulo,
                    bid.maxIndex,
                    keccak256(abi.encodePacked(bid.indexes)),
                    keccak256(abi.encodePacked(bid.excludedIndexes)),
                    keccak256(abi.encodePacked(bid.baseType)),
                    keccak256(abi.encodePacked(bid.attributes)),
                    bid.amount
                ),
                abi.encode(
                    bid.listingTime,
                    bid.expirationTime,
                    bid.salt
                ),
                abi.encode(nonce)
            )
        );
    }

    /**
     * @dev Retrieve hash to be signed
     * @param bidHash Bid hash
     * @return hash The EIP712 hash to be signed
     */
    function _hashToSign(bytes32 bidHash) internal view returns (bytes32 hash) {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparator, bidHash));
    }
}