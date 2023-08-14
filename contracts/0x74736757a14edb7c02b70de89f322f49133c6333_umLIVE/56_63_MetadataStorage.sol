// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {TokenMetadata} from "../../libraries/TokenMetadata.sol";

library MetadataStorage {
    // struct Attribute {
    //     string trait_type;
    //     string value;
    // }
    struct Metadata {
        string description; // "Umphrey's McGee Nashville, TN 12/15/2020. Collection of all songs in the Lively NFT player and the ability to mint out all the songs into individual NFTs."
        string external_url; // https://golive.ly
        string image; // https://golive.ly/metadata/1155/images/{id}.png
        string name; // UM Tour Dec 15th, 22 - Nashville
        string animation_url; // https://golive.ly/metadata/1155/animations/{id}.mp4
        TokenMetadata.Attribute[] attributes; // [{ "trait_type": "Artist", "value": "Umphrey's McGee"}]
    }

    struct Layout {
        mapping(uint256 => Metadata) metadata;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("lively.contracts.storage.MetadataStorage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}