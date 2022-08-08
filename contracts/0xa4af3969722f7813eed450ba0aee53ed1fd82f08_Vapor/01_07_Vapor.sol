// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

import {Item, Offer, ItemType} from "./VaporStructs.sol";
import "./VaporSignatures.sol";

contract Vapor is VaporSignatures {
    error InvalidOfferee();
    error InvalidOfferor();
    error InvalidType();
    error ExpiredOffer();
    error UsedOffer();

    // mapping from offer hash to bool
    mapping(bytes32 => bool) public offerUsed;

    string public constant NAME = "Vapor";
    string public constant VERSION = "1";

    bytes32 public immutable DOMAIN_SEPARATOR;

    constructor() VaporSignatures() {
        DOMAIN_SEPARATOR = getDomainSeparator(NAME, VERSION);
    }

    function acceptOffer(
        Offer memory offer,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        bytes32 offerHash = validateOffer(offer, v, r, s);
        offerUsed[offerHash] = true;

        uint256 i;
        for (; i < offer.toSend.length; ) {
            transferItem(offer.toSend[i], offer.from, offer.to);
            unchecked {
                ++i;
            }
        }

        i = 0;
        for (; i < offer.toReceive.length; ) {
            transferItem(offer.toReceive[i], offer.to, offer.from);
            unchecked {
                ++i;
            }
        }
    }

    function cancelOffer(Offer memory offer) public {
        if (msg.sender != offer.from) {
            revert InvalidOfferor();
        }
        offerUsed[hash(offer)] = true;
    }

    function transferItem(
        Item memory item,
        address from,
        address to
    ) internal {
        if (item.itemType == ItemType.ERC20) {
            IERC20(item.token).transferFrom(from, to, item.value);
            return;
        } else if (item.itemType == ItemType.ERC721) {
            IERC721(item.token).safeTransferFrom(from, to, item.value);
            return;
        }
        revert InvalidType();
    }

    function validateOffer(
        Offer memory offer,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (bytes32) {
        bytes32 offerHash = hash(offer);
        if (offerUsed[offerHash]) {
            revert UsedOffer();
        }
        if (block.timestamp > offer.deadline) {
            revert ExpiredOffer();
        }
        if (offer.to != address(0) && offer.to != msg.sender) {
            revert InvalidOfferee();
        }
        if (
            ecrecover(getTypedDataHash(DOMAIN_SEPARATOR, offerHash), v, r, s) !=
            offer.from
        ) {
            revert InvalidOfferor();
        }
        return offerHash;
    }
}