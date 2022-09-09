// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./Base64.sol";
import "./interfaces/ITokenURIBuilder.sol";

contract TokenURIBuilder is ITokenURIBuilder {
    bytes public constant JSON_URI_PREFIX = "data:application/json;base64,";

    function build(
        IMetadata metadata,
        IStrings strings,
        uint256 seedOrTokenId,
        string memory imageUri,
        string memory imageDataUri,
        string memory description,
        string memory externalUrl,
        string memory prefix,
        uint8[] memory meta
    ) external view returns (string memory) {
        string memory json = _getJsonPreamble(seedOrTokenId, description, externalUrl, prefix);        
        json = string(
            abi.encodePacked(
                json,
                '"image":"',
                imageUri,
                '",',
                '"image_data":"',
                imageDataUri,
                '",',
                getAttributes(meta, metadata, strings),
                "}"
            )
        );
        return _encodeJson(json);
    }

    function _getJsonPreamble(uint256 tokenId, string memory description, string memory externalUrl, string memory prefix)
        private
        pure
        returns (string memory json)
    {
        json = string(
            abi.encodePacked(
                '{"description":"',
                description,
                '","external_url":"',
                externalUrl,
                '","name":"',
                prefix, " #", Strings.toString(tokenId),
                '",'
            )
        );
    }

    function _encodeJson(string memory json)
        private
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    JSON_URI_PREFIX,
                    Base64.encode(bytes(json), bytes(json).length)
                )
            );
    }

    function getAttributes(uint8[] memory meta, IMetadata metadata, IStrings strings)
        public
        view
        returns (string memory attributes)
    {
        attributes = string(abi.encodePacked('"attributes":['));        
        uint8 numberOfTraits;
        for (uint8 i = 0; i < meta.length; i++) {
            uint8 value = meta[i];            
            string memory traitName = metadata.getTraitName(value);
            string memory label = strings.getString(value);            
            (string memory a, uint8 t) = _appendTrait(
                attributes,
                traitName,
                label,
                numberOfTraits
            );
            attributes = a;
            numberOfTraits = t;
        }
        attributes = string(abi.encodePacked(attributes, "]"));
    }

    function _appendTrait(
        string memory attributes,
        string memory trait_type,
        string memory value,
        uint8 numberOfTraits
    ) private pure returns (string memory, uint8) {
        if (bytes(value).length > 0) {
            numberOfTraits++;
            attributes = string(
                    abi.encodePacked(
                        attributes,
                        numberOfTraits > 1 ? "," : "",
                        '{"trait_type":"',
                        trait_type,
                        '","value":"',
                        value,
                        '"}'
                    )
                );
        }
        return (attributes, numberOfTraits);
    }
}