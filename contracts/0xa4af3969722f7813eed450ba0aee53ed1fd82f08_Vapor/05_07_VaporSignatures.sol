// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Item, Offer} from "./VaporStructs.sol";
import {ITEM_TYPEHASH, OFFER_TYPEHASH, DOMAIN_TYPEHASH} from "./VaporConstants.sol";

abstract contract VaporSignatures {
    function getDomainSeparator(string memory name, string memory version)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    DOMAIN_TYPEHASH,
                    keccak256(bytes(name)),
                    keccak256(bytes(version)),
                    block.chainid,
                    address(this)
                )
            );
    }

    function getTypedDataHash(bytes32 domainSeparator, bytes32 offerHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(abi.encodePacked("\x19\x01", domainSeparator, offerHash));
    }

    function hash(Offer memory offer) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    OFFER_TYPEHASH,
                    hash(offer.toSend),
                    hash(offer.toReceive),
                    offer.from,
                    offer.to,
                    offer.deadline
                )
            );
    }

    function hash(Item[] memory items) internal pure returns (bytes32) {
        bytes32[] memory itemHashes = new bytes32[](items.length);
        uint256 i;
        for (; i < items.length; ) {
            itemHashes[i] = hash(items[i]);
            unchecked {
                ++i;
            }
        }
        return keccak256(abi.encodePacked(itemHashes));
    }

    function hash(Item memory item) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(ITEM_TYPEHASH, item.token, item.itemType, item.value)
            );
    }
}