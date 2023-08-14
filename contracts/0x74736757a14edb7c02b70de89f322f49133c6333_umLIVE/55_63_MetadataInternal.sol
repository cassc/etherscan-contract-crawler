// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {MetadataStorage} from "./MetadataStorage.sol";
import {TokenMetadata} from "../../libraries/TokenMetadata.sol";
import {OwnableInternal} from "@solidstate/contracts/access/ownable/OwnableInternal.sol";

contract MetadataInternal is OwnableInternal {
    using MetadataStorage for MetadataStorage.Layout;

    function _setMetadata(
        uint256 _tokenId,
        MetadataStorage.Metadata calldata _metadata
    ) internal onlyOwner {
        MetadataStorage.Layout storage metadataStore = MetadataStorage.layout();

        metadataStore.metadata[_tokenId].description = _metadata.description;
        metadataStore.metadata[_tokenId].external_url = _metadata.external_url;
        metadataStore.metadata[_tokenId].image = _metadata.image;
        metadataStore.metadata[_tokenId].name = _metadata.name;
        metadataStore.metadata[_tokenId].animation_url = _metadata
            .animation_url;
        // metadata.attributes = _metadata.attributes;

        uint256 attributesLength = _metadata.attributes.length;
        uint256 i = 0;
        while (i < attributesLength) {
            metadataStore.metadata[_tokenId].attributes.push(
                _metadata.attributes[i]
            );
            i++;
        }
    }

    function _getMetadata(
        uint256 _tokenId
    ) internal view returns (string memory) {
        return
            TokenMetadata.makeMetadataJSON(
                _tokenId,
                msg.sender,
                MetadataStorage.layout().metadata[_tokenId].name,
                MetadataStorage.layout().metadata[_tokenId].image,
                MetadataStorage.layout().metadata[_tokenId].description,
                MetadataStorage.layout().metadata[_tokenId].attributes
            );
    }
}