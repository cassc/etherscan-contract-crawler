//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "./StringsLib.sol";

import "../interfaces/IMetadata.sol";
import "../interfaces/IAttribute.sol";
import "../interfaces/IBitGem.sol";
import "../libraries/SVGTemplatesLib.sol";

/* solhint-disable mark-callable-contracts */
/* solhint-disable var-name-mixedcase */
/* solhint-disable no-unused-vars */
/* solhint-disable two-lines-top-level-separator */
/* solhint-disable quotes */
/* solhint-disable indent */

library MetadataLib {
    using Strings for uint256;

    bytes32 internal constant TYPE_HASH = keccak256("type");
    bytes32 internal constant CLAIM_HASH = keccak256("claim");

    /// @notice return the name of the metadata
    function name(MetadataContract storage self)
        internal
        view
        returns (string memory) { return self._name; }

    /// @notice return the symnbol of the metadata
    function symbol(MetadataContract storage self)
        internal
        view
        returns (string memory) { return self._symbol; }

    /// @notice return the description of the metadata
    function description(MetadataContract storage self)
        internal
        view
        returns (string memory) { return self._description; }

    /// @notice return the image of the metadata
    function image(MetadataContract storage self)
        internal
        view
        returns (string memory) {
            return self._imageName;
        }

    /// @notice See {IERC721Metadata-tokenURI}.
    function tokenURI(
        MetadataContract storage self,
        AttributeContract storage attribs,
        uint256 tokenId
    ) internal view returns (string memory) {

        // turn the attributes into traits
        Trait[] memory traits = new Trait[](attribs.attributeKeys[tokenId].length);
        string[] memory valueIndicesString = new string[](attribs.attributeKeys[tokenId].length);
        for (uint256 i = 0; i < attribs.attributeKeys[tokenId].length; i++) {
            Attribute storage attrib = attribs.attributes[tokenId][attribs.attributeKeys[tokenId][i]];
            traits[i] = Trait("", attrib.key, attrib.value);
            valueIndicesString[i] = attrib.valueIndex.toString();
        }
        string memory imageUrl = string(abi.encodePacked(self._imageName, StringsLib.join(valueIndicesString, ""), ".png"));
        // base64 encode the token data and return it
        string memory json = Base64.encode(
            bytes(getTokenMetadata(self, traits, imageUrl, true, tokenId))
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function contractURI(MetadataContract storage self)
        internal
        view
        returns (string memory _ret) {
        Trait[] memory dum;
        _ret = self._imageName;
        string memory json = Base64.encode(
            bytes(
                getTokenMetadata(self, dum,  _ret, false, 0)
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    /// @notice create a metadata trait
    function createTrait(
        string memory displayType,
        string memory key,
        string memory value
    ) internal pure returns (string memory trait) {
        // ensure key is not empty
        require(bytes(key).length > 0, "key cannot be empty");
        // if has a display type, then output the display type
        bool hasDisplayType = bytes(displayType).length > 0;
        if (hasDisplayType) {
            displayType = string(
                abi.encodePacked('"display_type": "', displayType, '",')
            );
            // if this is a number, then don't quote it, otherwise quote it
            bool isNumber = StringsLib.startsWith(displayType, "number") ||
                StringsLib.endsWith(displayType, "percentage");
            if (!isNumber) value = string(abi.encodePacked('"', value, '"'));
            else value = string(abi.encodePacked(value));
        } else value = string(abi.encodePacked('"', value, '"'));
        // return the trait
        trait = string(
            abi.encodePacked(
                "{",
                displayType,
                '"trait_type": "',
                key,
                '", "value": ',
                value,
                "}"
            )
        );
    }

    /// @notice given an array of trait structs, create a metadata string
    function arrayizeTraits(Trait[] memory _traits)
        internal
        pure
        returns (string memory _traitsString)
    {
        bytes memory traitBytes = "[";
        for (uint256 i = 0; i < _traits.length; i++) {
            Trait memory traitObj = _traits[i];
            string memory trait = createTrait(
                traitObj.displayType,
                traitObj.key,
                traitObj.value
            );
            traitBytes = abi.encodePacked(traitBytes, trait);
            if (i < _traits.length - 1) {
                traitBytes = abi.encodePacked(traitBytes, ",");
            }
        }
        _traitsString = string(abi.encodePacked(traitBytes, "]"));
    }

    /// @notice create a metadata string from a metadata struct
    function getTokenMetadata(
        MetadataContract memory definition,
        Trait[] memory _traits,
        string memory _imageData,
        bool isToken,
        uint256 tokenId
    ) internal pure returns (string memory metadata) {
        string memory traitsString = arrayizeTraits(_traits);
        string memory externalUrl = bytes(definition._externalUri).length > 0
            ? string(
                abi.encodePacked(
                    '", "external_url": "',
                    definition._externalUri,
                    '"'
                )
            )
            : '"';
        bytes memory a1 = abi.encodePacked(
            '{"name": "',
            isToken ? string(abi.encodePacked(definition._name, " #", tokenId.toString())) : definition._name,
            '", "image": "',
            _imageData,
            '", "description": "',
            definition._description,
            externalUrl
        );
        if (_traits.length > 0) {
            a1 = abi.encodePacked(a1, ', "attributes": ', traitsString);
        }
        metadata = string(abi.encodePacked(a1, "}"));
    }
}