// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "solmate/utils/SSTORE2.sol";

import "openzeppelin/access/AccessControl.sol";
import "openzeppelin/utils/Base64.sol";
import "openzeppelin/utils/Strings.sol";

import "./IMetadataStore.sol";

library MetadataComposer {
    using Strings for uint256;
    using Base64 for string;

    string constant NAME = "Keycard";
    string constant DESCRIPTION = "Applied Primate Engineering, Maximum Security Clearance";

    function tokenURI(uint256 tokenId, bytes32[] memory metadataKeys, bytes32 imageKey, address metadataStore_)
        public
        view
        returns (string memory)
    {
        IMetadataStore metadataStore = IMetadataStore(metadataStore_);
        (bytes memory image, bytes memory animation) = metadataStore.readImage(imageKey);
        bytes memory json = abi.encodePacked("{", _jsonify("image", image), ",");
        json = abi.encodePacked(json, _jsonify("animation_url", animation), ",");
        json = abi.encodePacked(json, _jsonify("name", abi.encodePacked(NAME, " #", tokenId.toString())), ",");
        json = abi.encodePacked(json, _jsonify("description", bytes(DESCRIPTION)), ",");
        json = abi.encodePacked(json, '"attributes" : [');
        for (uint256 i = 0; i < metadataKeys.length; i++) {
            MetadataAttribute memory attribute = metadataStore.readAttribute(metadataKeys[i]);
            if (bytes(attribute.value).length > 0) {
                json = abi.encodePacked(json, _jsonifyAttribute(attribute));
                if (i != (metadataKeys.length - 1)) json = abi.encodePacked(json, ",");
            }
        }
        json = abi.encodePacked(json, "]}");

        string memory uri = string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
        return uri;
    }

    function _jsonifyAttribute(MetadataAttribute memory attribute) private pure returns (bytes memory) {
        bytes memory value = abi.encodePacked('"value":"', attribute.value, '"');
        if (bytes(attribute.trait).length == 0) {
            return abi.encodePacked("{", value, "}");
        }
        bytes memory trait = abi.encodePacked('"trait_type":"', attribute.trait, '"');
        return abi.encodePacked("{", trait, ",", value, "}");
    }

    function _jsonify(string memory key, bytes memory value) private pure returns (bytes memory) {
        return abi.encodePacked('"', key, '":"', value, '"');
    }
}