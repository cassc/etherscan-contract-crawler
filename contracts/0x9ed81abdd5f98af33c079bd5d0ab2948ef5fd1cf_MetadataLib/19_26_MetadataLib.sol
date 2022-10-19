//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "./StringsLib.sol";

import "../interfaces/IMetadata.sol";
import "../interfaces/IAttribute.sol";
import "../interfaces/IDiamond.sol";

import "../libraries/SVGTemplatesLib.sol";
import "../libraries/AttributeLib.sol";

import "../utilities/SVGManager.sol";

import "hardhat/console.sol";

/* solhint-disable mark-callable-contracts */
/* solhint-disable var-name-mixedcase */
/* solhint-disable no-unused-vars */
/* solhint-disable two-lines-top-level-separator */
/* solhint-disable quotes */
/* solhint-disable indent */

struct MetadataStorage {
    MetadataContract metadata;
}

library MetadataLib {
    using Strings for uint256;
    using StringsLib for string;
    using AttributeLib for AttributeContract;

    bytes32 internal constant TYPE_HASH = keccak256("type");
    bytes32 internal constant CLAIM_HASH = keccak256("claim");
      
    bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("diamond.nextblock.bitgem.app.MetadataStorage.storage");

    function metadataStorage() internal pure returns (MetadataStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function setMetadata(MetadataContract storage, MetadataContract memory _contract) internal {
        metadataStorage().metadata = _contract;
    }

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
            (, string memory svg) = getContractImage(self);
            return svg;
        }

    /// @notice get the image for the contract
    function getContractImage(
        MetadataContract storage self
    ) internal view returns (address addr, string memory svg) {

        // get the image, error if no image
        SVGManager mgr = SVGManager(SVGTemplatesLib.svgStorage().svgManager);

        try mgr.svgAddress(self._imageName) returns (address _addr) {
            address imageAddress = addr = _addr;
            require(imageAddress != address(0), "no image hash been set");   
            
            string[] memory cccc = new string[](4);
            cccc[0] = "CUT";
            cccc[1] = "COLOR";
            cccc[2] = "CARAT";
            cccc[3] = "CLARITY";
            Replacement[] memory replacements =
                _getReplacements(
                    self._imageColors,
                    cccc
                );

            svg = ISVGTemplate(imageAddress).buildSVG(replacements);
        } catch(bytes memory) {
            svg = self._imageName;
        }
    }

    /// @notice get the image for the gem
    function getTokenImage(
        MetadataContract storage,
        DiamondContract storage,
        AttributeContract storage a,
        uint256 tokenId
    ) internal view returns (string memory svg, Attribute[] memory attributes) {

        // get the attributes for the token
        string[] memory attributeKeys = AttributeLib._getAttributeKeys(a, tokenId);
        attributes = new Attribute[](attributeKeys.length);
        string[] memory cccc = AttributeLib._getAttributeValues(tokenId);

        for(uint256 i = 0; i < attributeKeys.length; i++) {
            attributes[i] = Attribute({
                key: attributeKeys[i],
                attributeType: AttributeType.String,
                value: cccc[i]
            });
        }

        // get the image, error if no image
        string memory key = string(abi.encodePacked("image_", tokenId.toString()));
        string memory val = AttributeLib._getAttribute(a, tokenId, key).value;
        svg = val;
        
        // Replacement[] memory replacements;
        // if (!val.startsWith('0x')) {
        //     svg = val;
        // } else {
        //     SVGManager mgr = SVGManager(SVGTemplatesLib.svgStorage().svgManager);
        //     address imageAddress = mgr.svgAddress(key);
        //     if (imageAddress == address(0)) imageAddress = mgr.svgAddress(self._imageName);
        //     replacements =
        //     _getReplacements(
        //         self._imageColors,
        //         cccc);
        //     svg = ISVGTemplate(imageAddress).buildSVG(replacements);
        // }
    }

    function setTokenImage(
        MetadataContract storage,
        AttributeContract storage a,
        uint256 tokenId,
        string memory svg
    ) internal {
        string memory key = string(abi.encodePacked("image_", tokenId.toString()));
        a._setAttribute(tokenId, Attribute(
            key,
            AttributeType.String,
            svg
        ));
    }

    /// @notice get th replacement values for the svg
    function _getReplacements(
        string[] memory colorPalette,
        string[] memory cccc
    ) internal pure returns (Replacement[] memory) {
        if(colorPalette.length == 0) {
            return new Replacement[](4);
        }
        Replacement[] memory replacements = new Replacement[](
            colorPalette.length + 4
        );
        for (uint256 i = 0; i < colorPalette.length; i++) {
            replacements[i] = Replacement(
                string(abi.encodePacked("COLOR ", Strings.toString(i))),
                colorPalette[i]
            );
        }
        uint256 l = colorPalette.length;
        replacements[l] = Replacement("CUT", cccc[0]);
        replacements[l + 1] = Replacement("COLOR", cccc[1]);
        replacements[l + 2] = Replacement("CARAT", cccc[2]);
        replacements[l + 3] = Replacement("CLARITY", cccc[3]);
        return replacements;
    }


    /// @notice See {IERC721Metadata-tokenURI}.
    function tokenURI(
        MetadataContract storage self,
        DiamondContract storage diamond,
        AttributeContract storage attribs,
        uint256 tokenId
    ) internal view returns (string memory) {

        // get the token image and attributes
        (string memory svg, Attribute[] memory attributes) = getTokenImage(
            self,
            diamond,
            attribs,
            tokenId
        );

        // turn the attributes into traits
        Trait[] memory traits = new Trait[](attributes.length);
        string memory _name = diamond.settings.name;
        for (uint256 i = 0; i < attributes.length; i++) {
            traits[i] = Trait("", attributes[i].key, attributes[i].value);
            // add the word 'claim' to the name if the attribute is a claim
            if (
                TYPE_HASH == keccak256(bytes(attributes[i].key)) &&
                CLAIM_HASH == keccak256(bytes(attributes[i].value))
            ) {
                _name = string(abi.encodePacked(_name, " Claim"));
            }
        }
        // base64 encode the token data and return it
        string memory json = Base64.encode(
            bytes(getTokenMetadata(self, traits, svg))
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function contractURI(MetadataContract storage self)
        internal
        view
        returns (string memory) {
        Trait[] memory dum;
        (, string memory svg) = getContractImage(self);
        string memory json = Base64.encode(
            bytes(
                getTokenMetadata(self, dum,  svg)
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
        string memory _imageData
    ) internal pure returns (string memory metadata) {
        if(!_imageData.startsWith("0x")) {
            _imageData = string(abi.encodePacked('"', _imageData, '"'));
        }
        string memory traitsString = arrayizeTraits(_traits);
        string memory externalUrl = bytes(definition._externalUri).length > 0
            ? string(
                abi.encodePacked(
                    '"external_url": "',
                    definition._externalUri,
                    '"'
                )
            )
            : string(abi.encodePacked('"external_url"', ': "', '"'));
        bytes memory a1 = abi.encodePacked(
            '{"name": "',
            definition._name,
            '", "image": ',
            _imageData,
            ', "description": "',
            definition._description,
            '", ',
            externalUrl
        );
        if (_traits.length > 0) {
            a1 = abi.encodePacked(a1, ', "attributes": ', traitsString);
        }
        metadata = string(abi.encodePacked(a1, "}"));
    }
}