// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

import "./Presentation.sol";
import "./IERC721.sol";
import "./CrypToadzChained.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

/**
 @notice A contract proxy to fix issues with the original contract. Also makes additional patches (i.e. as-yet unidentified browser issues) cheaper, by making core methods public.
 */
contract CrypToadzChainedPatch {
    bytes public constant LEGACY_URI_NOT_FOUND =
        "ERC721Metadata: URI query for nonexistent token";

    bytes public constant JSON_URI_PREFIX = "data:application/json;base64,";
    bytes public constant PNG_URI_PREFIX = "data:image/png;base64,";
    bytes public constant GIF_URI_PREFIX = "data:image/gif;base64,";
    bytes public constant SVG_URI_PREFIX = "data:image/svg+xml;base64,";

    bytes public constant DESCRIPTION =
        "A small, warty, amphibious creature that resides in the metaverse.";
    bytes public constant EXTERNAL_URL = "https://cryptoadz.io";
    bytes public constant NAME = "CrypToadz";

    CrypToadzChained parent;

    address public immutable stop;

    constructor(address _parent) {
        parent = CrypToadzChained(_parent);
        stop = SSTORE2.write(
            hex"7b2274726169745f74797065223a22437573746f6d222c2276616c7565223a22312f31227d2c7b2274726169745f74797065223a224e616d65222c2276616c7565223a22467265616b792046726f677a227d2c7b2274726169745f74797065223a222320547261697473222c2276616c7565223a327d"
        );
    }

    function isCustomImage(uint256 tokenId) public view virtual returns (bool) {
        return
            ICrypToadzCustomImages(parent.customImages()).isCustomImage(
                tokenId
            );
    }

    function isCustomAnimation(uint256 tokenId)
        public
        view
        virtual
        returns (bool)
    {
        return
            ICrypToadzCustomAnimations(parent.customAnimations())
                .isCustomAnimation(tokenId);
    }

    function tokenURIWithPresentation(
        uint256 tokenId,
        Presentation presentation
    ) external view virtual returns (string memory tokenUri) {
        uint8[] memory meta = ICrypToadzMetadata(parent.metadata()).getMetadata(
            tokenId
        );
        require(meta.length > 0, string(LEGACY_URI_NOT_FOUND));

        bool ignoreWrapRequest = false;
        bool isCustom = isCustomImage(tokenId) || isCustomAnimation(tokenId);

        if (isCustom) {
            if (
                // large images (34)
                tokenId == 316 ||
                tokenId == 703 ||
                tokenId == 916 ||
                tokenId == 936 ||
                tokenId == 1005 ||
                tokenId == 1793 ||
                tokenId == 1812 ||
                tokenId == 1975 ||
                tokenId == 2232 ||
                tokenId == 2327 ||
                tokenId == 2489 ||
                tokenId == 2521 ||
                tokenId == 2709 ||
                tokenId == 2825 ||
                tokenId == 2846 ||
                tokenId == 2959 ||
                tokenId == 3196 ||
                tokenId == 3309 ||
                tokenId == 3382 ||
                tokenId == 4096 ||
                tokenId == 4152 ||
                tokenId == 4238 ||
                tokenId == 4580 ||
                tokenId == 4714 ||
                tokenId == 4773 ||
                tokenId == 4896 ||
                tokenId == 5128 ||
                tokenId == 5471 ||
                tokenId == 5902 ||
                tokenId == 6214 ||
                tokenId == 6382 ||
                tokenId == 6491 ||
                tokenId == 6572 ||
                tokenId == 6631 ||
                // large animations (8)
                tokenId == 37 ||
                tokenId == 318 ||
                tokenId == 466 ||
                tokenId == 1943 ||
                tokenId == 3661 ||
                tokenId == 4035 ||
                tokenId == 4911 ||
                tokenId == 5086
            ) {
                // cancel the wrap request for large rasters
                ignoreWrapRequest = true;
            }
        }

        string memory imageUri = getImageURI(tokenId, meta);
        string memory imageDataUri;
        if (
            (presentation == Presentation.ImageData ||
                presentation == Presentation.Both) && !ignoreWrapRequest
        ) {
            imageDataUri = getWrappedImage(imageUri);
        }

        string memory json = getJsonPreamble(tokenId);

        if (
            (presentation == Presentation.Image ||
                presentation == Presentation.Both) || ignoreWrapRequest
        ) {
            json = string(abi.encodePacked(json, '"image":"', imageUri, '",'));
        }

        if (
            (presentation == Presentation.ImageData ||
                presentation == Presentation.Both) && !ignoreWrapRequest
        ) {
            json = string(
                abi.encodePacked(json, '"image_data":"', imageDataUri, '",')
            );
        }

        return
            encodeJson(
                string(abi.encodePacked(json, getAttributes(meta, false), "}"))
            );
    }

    function getJsonPreamble(uint256 tokenId)
        public
        pure
        virtual
        returns (string memory json)
    {
        json = string(
            abi.encodePacked(
                '{"description":"',
                DESCRIPTION,
                '","external_url":"',
                EXTERNAL_URL,
                '","name":"',
                NAME,
                " #",
                Strings.toString(tokenId),
                '",'
            )
        );
    }

    function getImageURI(uint256 tokenId, uint8[] memory meta)
        public
        view
        virtual
        returns (string memory imageUri)
    {
        if (isCustomImage(tokenId)) {
            bytes memory customImage = ICrypToadzCustomImages(
                parent.customImages()
            ).getCustomImage(tokenId);
            imageUri = string(
                abi.encodePacked(
                    PNG_URI_PREFIX,
                    Base64.encode(customImage, customImage.length)
                )
            );
        } else if (isCustomAnimation(tokenId)) {
            bytes memory customAnimation = ICrypToadzCustomAnimations(
                parent.customAnimations()
            ).getCustomAnimation(tokenId);
            imageUri = string(
                abi.encodePacked(
                    GIF_URI_PREFIX,
                    Base64.encode(customAnimation, customAnimation.length)
                )
            );
        } else {
            GIF memory gif = ICrypToadzBuilder(parent.builder()).getImage(
                meta,
                tokenId
            );
            imageUri = IGIFEncoder(parent.encoder()).getDataUri(gif);
        }
    }

    function encodeJson(string memory json)
        public
        pure
        virtual
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

    function getWrappedImage(string memory imageUri)
        public
        pure
        virtual
        returns (string memory imageDataUri)
    {
        string memory imageData = string(
            abi.encodePacked(
                '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 36 36" x="0" y="0" width="100%" height="100%" style="',
                "image-rendering:pixelated;image-rendering:-moz-crisp-edges;-ms-interpolation-mode:nearest-neighbor;",
                "background-color:#00FFFFFF;background-repeat:no-repeat;background-size:100%;background-image:url(",
                imageUri,
                ');"></svg>'
            )
        );

        imageDataUri = string(
            abi.encodePacked(
                SVG_URI_PREFIX,
                Base64.encode(bytes(imageData), bytes(imageData).length)
            )
        );
    }

    function getAttributes(uint8[] memory meta, bool includeSize)
        public
        view
        virtual
        returns (string memory attributes)
    {
        attributes = string(abi.encodePacked('"attributes":['));
        if (meta[0] == 255)
            return
                string(abi.encodePacked(attributes, SSTORE2.read(stop), "]"));

        uint8 numberOfTraits;
        for (uint8 i = includeSize ? 0 : 1; i < meta.length; i++) {
            uint8 value = meta[i];
            if (value == 254) continue; // stop byte
            string memory traitName = getTraitName(value);

            string memory label = ICrypToadzStrings(parent.strings()).getString(
                    // Vampire
                    value == 249 ? 55 : value == 250
                        ? 55 // Undead
                        : value == 252
                        ? 37 // Creep
                        : value == 253
                        ? 20
                        : value
                );

            (string memory a, uint8 t) = appendTrait(
                value >= 112 && value < 119,
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

    function appendTrait(
        bool isNumber,
        string memory attributes,
        string memory trait_type,
        string memory value,
        uint8 numberOfTraits
    ) public pure virtual returns (string memory, uint8) {
        if (bytes(value).length > 0) {
            numberOfTraits++;

            if (isNumber) {
                attributes = string(
                    abi.encodePacked(
                        attributes,
                        numberOfTraits > 1 ? "," : "",
                        '{"trait_type":"',
                        trait_type,
                        '","value":',
                        value,
                        "}"
                    )
                );
            } else {
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
        }
        return (attributes, numberOfTraits);
    }

    function getTraitName(uint8 traitValue)
        public
        pure
        virtual
        returns (string memory)
    {
        if (traitValue >= 0 && traitValue < 17) {
            return "Background";
        }
        if (traitValue >= 17 && traitValue < 51) {
            return "Body";
        }
        if (traitValue >= 51 && traitValue < 104) {
            if (traitValue == 55) return "Mouth"; // Vampire
            return "Head";
        }
        if (traitValue >= 104 && traitValue < 112) {
            return "Accessory II";
        }
        if (traitValue >= 112 && traitValue < 119) {
            return "# Traits";
        }
        if (traitValue >= 119 && traitValue < 121) {
            return "Size";
        }
        if (traitValue >= 121 && traitValue < 138) {
            return "Mouth";
        }
        if (traitValue >= 138 && traitValue < 168) {
            return "Eyes";
        }
        if (traitValue >= 168 && traitValue < 174) {
            return "Custom";
        }
        if (traitValue >= 174 && traitValue < 237) {
            return "Name";
        }
        if (traitValue >= 237 && traitValue < 246) {
            return "Accessory I";
        }
        if (traitValue >= 246 && traitValue < 249) {
            return "Clothes";
        }

        if (traitValue == 249) return "Head"; // Vampire
        if (traitValue == 250) return "Eyes"; // Vampire

        if (traitValue == 251) return "Size";

        if (traitValue == 252) return "Eyes"; // Undead
        if (traitValue == 253) return "Eyes"; // Creep

        revert TraitOutOfRange(traitValue);
    }
}