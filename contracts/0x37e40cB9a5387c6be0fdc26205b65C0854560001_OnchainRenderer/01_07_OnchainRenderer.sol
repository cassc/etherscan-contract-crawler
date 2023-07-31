// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/**===============================================================================
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@,,,,,,,,,@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,@@(((((,,,,,,,,,@@,,,,,@@((,,,,,,,,,,  @@,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,@@(((((,,,,,,,,,,,,,@@@@@((,,,,,,,,,,,,,,  @@,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,@@@((((,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,  @@@,,,,,,,,,,,,,,,
,,,,,,,,,,,,@@(((((((,,,,,,,,,,,,,,,,@@,,,,,,,,,,,,@@@@@@@@@@@,,,,,@@,,,,,,,,,,,,,
,,,,,,,,,,,,@@(((((((,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@    @@,,,@@,,,,,,,,,,,,,
,,,,,,,,,,@@(((((((,,,,@@@@@@@@@@@@@@,,@@@,,,,@@     @@@@@    @@,,,,,@@,,,,,,,,,,,
,,,,,,,,,,@@(((((((,,,,,,,,,,,,,,,,,,@@@@@,,,,@@   @@@@@@@    @@,,,,,@@,,,,,,,,,,,
,,,,,,,@@@(((((((((,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@,,,,,,,,,@@@,,,,,,,,
,,,,,,,@@@(((((((((@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@,,,,,,,,
,,,,,,,@@@((((((@@@(((((((@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@,,,,@@@,,,,,,,,
,,,,,,,@@@((((((@@@((@@(((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((((((@@,,@@@,,,,,,,,
,,,,,,,@@@((((((@@@((((@@@@@((((((((((((((((((((((((((((((((@@@@(((@@,,@@@,,,,,,,,
,,,,,,,@@@(((((((((@@(((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((((((@@,,@@@,,,,,,,,
,,,,,,,@@@(((((((((**##############################################,,**@@@,,,,,,,,
,,,,,,,,,,@@(((((((((((,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,((@@,,,,,,,,,,,
,,,,,,,,,,,,@@(((((((((((((((((((((((((((((((((((((((((((((((((((((@@,,,,,,,,,,,,,
,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
==================================================================================
🐸                          ON-CHAIN RENDERING LOGIC                            🐸
🐸                       THE PEOPLES' NFT MADE BY FROGS                         🐸
================================================================================*/

/**
 🐸 @title OnChainRenderManager
 🐸 @author @xtremetom
 🐸 @dev An experiment in storing stupidly huge amounts of data on-chain and
 🐸      using it convert a 20k collection of animated gifs into an on-chain
 🐸      collection with future ability to make the whole collection dynamic
 🐸
 🐸      You can tell just how stupid this is by the number of 🐸s
 🐸
 🐸
 🐸      ==================================
 🐸      🐸 TRAIT BUNDLE
 🐸      ==================================
 🐸      Each trait bundle has:
 🐸      - sprite sheet (png as bytes minus the first 24 bytes)
 🐸      - name (as bytes)
 🐸      - length of name (as bytes)
 🐸
 🐸      eg:
 🐸      4 | Blue | SpriteSheet.png
 🐸
 🐸      04 | 42 6c 75 65 | 06 c0 00 00 00 48 ...
 🐸
 🐸
 🐸      ==================================
 🐸      🐸 LAYER BUNDLE
 🐸      ==================================
 🐸      Each layer bundle is made of all the `trait bundle` related to that layer.
 🐸      When created, the index of the last byte for each `trait bundle`
 🐸      is recorded:
 🐸
 🐸      eg of trait bundles in a layer bundle:
 🐸      Alien | Ninja | Pirate
 🐸
 🐸      index of last trait bundle byte:
 🐸      157 | 350 | 600
 🐸
 🐸
 🐸      ==================================
 🐸      🐸 COLLECTION BUNDLE
 🐸      ==================================
 🐸      All the `layer bundles` are packed into a single collection bundle.
 🐸      When created, the last byte for each `layer bundle` is recorded:
 🐸
 🐸      eg of layer bundles in the collection bundle:
 🐸      backgrounds | bodies | hats | faces
 🐸
 🐸      index of last layer bundle byte:
 🐸      3500 | 6700 | 85_000 | 120_000 | 200_000
 🐸
 🐸
 🐸      ==================================
 🐸      🐸 STRUCTURE
 🐸      ==================================
 🐸
 🐸      Blue | Green | Orange        Alien | Ninja | Pirate        Smile | Frown | Laugh
 🐸      |                   |        |                    |        |                   |
 🐸      |                   |        |                    |        |                   |
 🐸      |                   |        |                    |        |                   |
 🐸      [LAYER BUNDLE --- BG]        [LAYER BUNDLE -- BODY]        [LAYER BUNDLE - FACE]
 🐸                |                             |                             |
 🐸                +--------------------+        |        +--------------------+
 🐸                                     |        |        |
 🐸                                     V        V        V
 🐸                                     [COLLECTION BUNDLE]
 🐸 ================================================================================*/

import "./lib/scripty2/interfaces/IContractScript.sol";
import "./lib/SmallSolady.sol";
import "./BundleManager.sol";
import "./lib/bytes/BytesLib.sol";

contract OnchainRenderer {

    using BytesLib for bytes;

    struct Layer {
        bytes name;
        bytes dom;
    }

    struct Settings {
        bool one_one;
        Layer backgroundLayer;
        Layer backLayer;
        Layer bodyLayer;
        Layer faceMaskLayer;
        Layer hatLayer;
        Layer faceLayer;
        Layer frontLayer;
    }

    address public immutable _scriptyStorageAddress;
    address public immutable _bundleManagerAddress;

    string constant IMG_HEADER = "iVBORw0KGgoAAAANSUhEUgAA";

    constructor(
        address scriptyStorageAddress,
        address bundleManagerAddress
    ) {
        _scriptyStorageAddress = scriptyStorageAddress;
        _bundleManagerAddress = bundleManagerAddress;
    }

    /**
     🐸 @notice Get to metadata for a given token ID
     🐸 @param tokenId - Token ID for desired token
     🐸 @return metadata as a string
     */
    function tokenURI(uint256 tokenId) public view returns (string memory) {

        string[2] memory jsonData = buildJSONData(tokenId);

        bytes memory json = abi.encodePacked(
            '{"name":"',
            'Baby Pepe: #',
            SmallSolady.toString(tokenId),
            '", "description":"',
            'Baby Pepes are mischievous little on-chain frogs that love memes and fun.',
            '","image":"data:image/svg+xml;base64,',
            jsonData[0],
            '",',
            jsonData[1],
            '}'
        );

        return string(
            abi.encodePacked(
                "data:application/json,",
                json
            )
        );
    }

    /**
     🐸 @notice Build the metadata json information
     🐸 @param tokenId - Token ID for desired token
     🐸 @return jsonData - array of strings for image and attributes
     */
    function buildJSONData(uint256 tokenId) internal view returns (string[2] memory jsonData) {

        Settings memory settings = buildSettings(tokenId);

        string memory svgHeader = '<svg class="a p" viewBox="0 0 72 72" xmlns="http://www.w3.org/2000/svg"><style>.a{width:576px;height:576px}.p{image-rendering:-webkit-optimize-contrast;-ms-interpolation-mode:nearest-neighbor;image-rendering:-moz-crisp-edges;image-rendering:pixelated}@keyframes f24{100%{background-position:-1728px 0}}div{width:72px;height:72px;animation:f24 2.4s steps(24) infinite}</style><svg class="p" viewBox="0 0 72 72" xmlns="http://www.w3.org/2000/svg">';
        string memory svgFooter = '</svg></svg>';

        // custom handling for Sexy
        if (settings.backgroundLayer.name.equal("Sexy")) {
            svgHeader = '<svg class="a p" viewBox="0 0 72 72" xmlns="http://www.w3.org/2000/svg"><style>.a{width:576px;height:576px}.p{image-rendering:-webkit-optimize-contrast;-ms-interpolation-mode:nearest-neighbor;image-rendering:-moz-crisp-edges;image-rendering:pixelated}@keyframes f67{100%{background-position:-4824px 0}}div{width:72px;height:72px;animation:f67 26.8s steps(67) infinite}</style><svg class="p" viewBox="0 0 72 72" xmlns="http://www.w3.org/2000/svg">';
        }

        jsonData[0] = SmallSolady.encode(
            abi.encodePacked(
                svgHeader,
                settings.backgroundLayer.dom,
                settings.backLayer.dom,
                settings.bodyLayer.dom,
                settings.faceMaskLayer.dom,
                settings.hatLayer.dom,
                settings.faceLayer.dom,
                settings.frontLayer.dom,
                svgFooter
            )
        );

        jsonData[1] = string(buildAttributes(settings));
    }

    /**
     🐸 @notice Build settings for tokenId
     🐸 @param tokenId - Token Id to build settings for
     🐸 @return settings - Settings for token Id
     🐸 @dev In the event that the token is a 1/1 it only requires a single layer
     🐸      as the 1/1 sprite sheet includes all layers in a single sheet.
     */
    function buildSettings(uint256 tokenId) internal view returns (Settings memory settings) {

        bytes[7] memory layerBundles = getLayerBundles();

        // Check for 1/1
        (bool is1_1, uint256 index) = isOneOfOne(tokenId);
        if (is1_1) {
            settings.backgroundLayer = buildLayer("one_one", layerBundles[6], index, "");
            settings.one_one = true;

            // set names for 1/1
            bytes memory name = settings.backgroundLayer.name;
            settings.bodyLayer.name = name;
            settings.hatLayer.name = name;
            settings.faceLayer.name = name;
            return settings;
        }

        BundleManager bundleManager = BundleManager(_bundleManagerAddress);

        // pull any custom traits for layers
        // - non custom traits return as an empty string ""
        bytes[4] memory customTraitBundleForLayers = bundleManager.getCustomTraitBundleForLayers(tokenId);

        bytes memory genePool = IContractScript(_scriptyStorageAddress).getScript("baby_pepes_genes", "");
        (uint8 backgroundIndex, uint8 bodyIndex, uint8 hatIndex, uint8 faceIndex) = getTraitIndices(tokenId, genePool);


        //==================================
        // 🐸 MAIN LAYERS:
        //==================================

        // Background
        settings.backgroundLayer = buildLayer("background", layerBundles[0], backgroundIndex, customTraitBundleForLayers[0]);

        // Body
        settings.bodyLayer = buildLayer("body", layerBundles[2], bodyIndex, customTraitBundleForLayers[1]);

        // Hat
        settings.hatLayer = buildLayer("hat", layerBundles[3], hatIndex, customTraitBundleForLayers[2]);

        // Face
        // If face needs masking, that means we have show it behind the hat
        // This is needed for faces like "ninja"
        Layer memory faceLayer = buildLayer("face", layerBundles[4], faceIndex, customTraitBundleForLayers[3]);
        (faceRequiresMasking(faceIndex))
        ? settings.faceMaskLayer = faceLayer
        : settings.faceLayer = faceLayer;


        //==================================
        // 🐸 SUB LAYERS:
        //==================================

        // Back (sublayer)
        if (settings.hatLayer.name.equal("Moon Warrior")) {
            settings.backLayer = buildLayer("back", layerBundles[1], 0, "");
        }

        // Front (sublayer)
        if (settings.bodyLayer.name.equal("Catchum")) {
            settings.frontLayer = buildLayer("front", layerBundles[5], 0, "");
        }
        else if (settings.bodyLayer.name.equal("Metal Head")) {
            settings.frontLayer = buildLayer("front", layerBundles[5], 1, "");
        }
    }

    /**
     🐸 @notice Build a single layer
     🐸 @param layerName - Layer being built
     🐸 @param layerBundle - Layer bundle to splice from
     🐸 @param index - Location of the required trait bundle
     🐸 @param customTraitBundle - Custom trait bundle | ""
     🐸 @return layer - Final layer ready for use
     🐸 @dev
     🐸      ==================================
     🐸      🐸 Custom Trait Bundle:
     🐸      ==================================
     🐸      This is favored over extracting trait bundle from layer bundle
     🐸
     🐸      [Custom Bundle Structure]
     🐸      unit8 name length | name | [sprite sheet as bytes]
     🐸
     🐸      [Example]
     🐸      03Bob{sprite sheet bytes}
     🐸
     🐸
     🐸      ==================================
     🐸      🐸 Layer Bundles:
     🐸      ==================================
     🐸      These are huge as explained in `getStartAndLength()`
     🐸      This function uses start and length splicing params to cut
     🐸      the required trait bundle from the layer bundle
     🐸
     🐸      [Structure]:
     🐸      03Cap{sprite sheet bytes}...06Beanie{sprite sheet bytes}...06Helmet{sprite sheet bytes}...
     🐸
     🐸      [Cut]:
     🐸      03Cap{sprite sheet bytes}...06Beanie{sprite sheet bytes}...06Helmet{sprite sheet bytes}...
     🐸                                  |                          |
     🐸                                  |                          |
     🐸                           [start][----------length----------]
     🐸                                  |                          |
     🐸                                  |                          |
     🐸                                  06Beanie{sprite sheet bytes}
     🐸
     🐸
     🐸      ==================================
     🐸      🐸 Building Sprite Sheets
     🐸      ==================================
     🐸      To save on deployment costs the sprite sheets are stored in the layer bundles as bytes.
     🐸      Not as bytes of the base64 encoded image. I also trim off the first 24 bytes as these are
     🐸      identical for all the sprite sheets.
     🐸
     🐸      To use the sprite sheet we first base64 encode the png bytes and then add the IMG_HEADER
     */
    function buildLayer (
        string memory layerName,
        bytes memory layerBundle,
        uint256 index,
        bytes memory customTraitBundle
    ) internal view returns (Layer memory layer) {

        bytes memory name;
        bytes memory spriteSheet;
        bytes memory traitBundle;

        // use custom or splice from layerBundle
        if (customTraitBundle.length > 0) {
            traitBundle = customTraitBundle;
        } else {
            (uint256 start, uint256 length) = getTraitBundleStartAndLength(index, layerName);
            traitBundle = layerBundle.slice(start, length);
        }

        (name, spriteSheet) = getNameAndSpriteSheet(traitBundle);
        layer.name = name;

        // Base64 encode raw sprite sheet png bytes
        string memory base64SpriteSheet = SmallSolady.encode(spriteSheet);

        if (spriteSheet.length > 0) {
            layer.dom = abi.encodePacked(
                '<foreignObject x="0" y="0" width="100%" height="100%">',
                '<div xmlns="http://www.w3.org/1999/xhtml" style="background-image:url(data:image/png;base64,', IMG_HEADER, base64SpriteSheet, ')"></div>',
                '</foreignObject>'
            );
        }
    }

    /**
     🐸 @notice Build single attribute
     🐸 @param key - Attribute key
     🐸 @param value - Attribute value
     🐸 @return trait - Attribute as bytes
     */
    function buildAttributeTrait(bytes memory key, bytes memory value) internal pure returns (bytes memory trait) {
        return abi.encodePacked('{"trait_type":"', key, '","value": "', value, '"}');
    }

    /**
     🐸 @notice Build metadata attributes
     🐸 @param settings - Settings for this token
     🐸 @return attr - Attributes as bytes
     */
    function buildAttributes(Settings memory settings) internal pure returns (bytes memory attr) {

        bytes memory babyType = "Baby";
        if (settings.backgroundLayer.name.equal("Gallery")) babyType = "Gallery";
        else if (settings.one_one) babyType = "1/1";

        // other tokens
        return abi.encodePacked(
            '"attributes": [',
                buildAttributeTrait("Background", settings.backgroundLayer.name),
                ',',
                buildAttributeTrait("Body", settings.bodyLayer.name),
                ',',
                buildAttributeTrait("Hat", settings.hatLayer.name),
                ',',
                buildAttributeTrait("Face", settings.faceLayer.name),
                ',',
                buildAttributeTrait("Type", babyType),
            ']'
        );
    }

    /**
     🐸 @notice Check if the token Id is a 1/1
     🐸 @param tokenId - Token ID for desired token
     🐸 @return isOneOfOne - bool 1/1
     🐸 @return i - index of 1/1
     */
    function isOneOfOne(uint256 tokenId) internal view returns (bool isOneOfOne, uint256 i) {
        uint16[7] memory list = BundleManager(_bundleManagerAddress).getOneOfOneList();

        unchecked {
            do {
                if (uint256(list[i]) == tokenId) isOneOfOne = true;
            } while (!isOneOfOne && ++i < 7);
        }

        return (isOneOfOne, i);
    }

    /**
     🐸 @notice Determine if a face trait needs to be masked
     🐸 @param traitId - Id of the trait to check
     🐸 @return requiresMasking - Boolean of masking needs
     🐸 @dev Masking is needed if the face trait crosses over the hat traits
     🐸      To fix this, the face trait is moved behind the hat trait
     */
    function faceRequiresMasking(uint256 traitId) internal view returns (bool requiresMasking) {
        uint8[] memory list = BundleManager(_bundleManagerAddress).getFaceMaskingList();
        uint256 len = list.length;
        uint256 i;

        unchecked {
            do {
                if (uint256(list[i]) == traitId) requiresMasking = true;
            } while (!requiresMasking && ++i < len);
        }
    }

    // =============================================================
    //                           UTILS
    // =============================================================

    /**
     🐸 @notice Split the collection bundle into layer bundles
     🐸 @return layerBundles - Array of layer bundles
     🐸 @dev See explanation starting at line 32
     */
    function getLayerBundles() internal view returns (bytes[7] memory layerBundles) {
        bytes memory collectionBundle = IContractScript(_scriptyStorageAddress).getScript("baby_pepes_all_layers", "");
        uint24[7] memory layerByteBoundaries = BundleManager(_bundleManagerAddress).getLayerByteBoundaries();

        uint256 i;
        uint256 start;
        uint256 length;
        unchecked {
            do {
                if (i > 0) start = uint256(layerByteBoundaries[i - 1]);
                length = uint256(layerByteBoundaries[i]) - start;

                layerBundles[i] = collectionBundle.slice(start, length);
            } while (++i < 7);
        }
    }

    /**
     🐸 @notice Split gene data into trait ids
     🐸 @param tokenId - Id of token to get data for
     🐸 @return backgroundTraitId - Trait id for background layer
     🐸 @return bodyTraitId - Trait id for body layer
     🐸 @return hatTraitId - Trait id for hat layer
     🐸 @return faceTraitId - Trait id for face layer
     🐸 @dev Genes is a huge data set containing the trait Ids for
     🐸      the whole collection
     🐸
     🐸      [Structure]:
     🐸      0101010105050535258901
     🐸
     🐸      [Example]:
     🐸      01 01 01 01    |   05 05 05 05      |   35 25 89 01
     🐸      Baby Pepe #1   |   Baby Pepe #2     |   Baby Pepe #3
     */
    function getTraitIndices(uint256 tokenId, bytes memory genePool) internal pure returns (
        uint8 backgroundTraitId,
        uint8 bodyTraitId,
        uint8 hatTraitId,
        uint8 faceTraitId
    ) {
        assembly {
            let offset := mul(sub(tokenId, 1), 4)
            let genes := mload(add(genePool, add(offset, 4)))
            backgroundTraitId := shr(24, genes)
            bodyTraitId := shr(16, genes)
            hatTraitId := shr(8, genes)
            faceTraitId := shr(0, genes)
        }
    }

    /**
     🐸 @notice Get the start and length of splice for a trait by index
     🐸 @param index - Index of the required bundle
     🐸 @param layerName - Name of the required layer bundle
     🐸 @return start - slicing start point
     🐸 @return length - slicing length
     🐸 @dev Using the known byte boundaries for the traits within the layer bundle, we can get the
     🐸      the starting bytes and total byte length for a desired trait bundle the layer bundle
     🐸
     🐸      traitBundle[0] starts at 1
     🐸      traitBundle[N] starts from traitBundle[N-1]+1
     🐸
     🐸      [Layer Bundle Structure]:
     🐸      03Cap{sprite sheet bytes}...06Beanie{sprite sheet bytes}...06Helmet{sprite sheet bytes}...
     🐸
     🐸      [Byte Boundaries Structure]:
     🐸      [150, 350, 600]
     🐸
     🐸      [Example Trait Slicing]:
     🐸      [1, 150]        |   [151, 350]      |   [351, 600]
     🐸      Trait #0        |   Trait #1        |   Trait #2
     */
    function getTraitBundleStartAndLength(uint256 index, string memory layerName) internal view returns (uint256 start, uint256 length) {

        uint256 end;

        string memory slotsFunction = string.concat("_", layerName, "Slots(uint256)");

        unchecked {
            if (index > 0) {
                (, bytes memory startData) = _bundleManagerAddress.staticcall(abi.encodeWithSignature(slotsFunction, index - 1));
                start = abi.decode(startData, (uint256));
            }

            (, bytes memory endData) = _bundleManagerAddress.staticcall(abi.encodeWithSignature(slotsFunction, index));
            end = abi.decode(endData, (uint256));

            return (start, end-start);
        }
    }

    /**
     🐸 @notice Get the sprite sheet and name from trait bundle
     🐸 @param bundle - bundle to split up
     🐸 @return name - Name of the trait
     🐸 @return spriteSheet - Sprite sheet of the trait
     */
    function getNameAndSpriteSheet(bytes memory bundle) internal view returns(bytes memory name, bytes memory spriteSheet) {
        uint8 nameLength;
        assembly {
            nameLength := mload(add(bundle, 1))
        }

        unchecked {
            uint256 offset = 1 + nameLength;
            name = bundle.slice(1, nameLength);
            spriteSheet = bundle.slice(offset, bundle.length - offset);
        }
    }
}