// SPDX-License-Identifier: MIT
// Copyright (c) 2022 Lawrence X. Rogers

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {BUD_STUB_1, BUD_STUB_2, FLOWER_ANIMATIONS, FLOWER_DEFS} from "contracts/Encodings.sol";

/// @title MergeFlowersArt
/// @author Lawrence X Rogers
/// @notice This smart contract creates the art for the MergeFlowers NFT.

contract MergeFlowerArt {
    using Strings for uint256;

    uint constant NUM_ATTRIBUTES = 4;

    /// @notice color information about the flower
    struct Palette {
        uint h1;            // hue1
        uint h2;            // hue2
        uint s;             // saturation
        uint l;             // lightness
        bool lwalk;         // whether to increase lightness per layer
        uint cycle;         // how many different colors in the palette
        Interval interval;  
        uint opacity;      
        Mutation mutation;  
    }

    /// @notice 
    struct FlowerTraits {
        Palette palette;
        uint maxDistance;      // starting distance of petals on first layer
        uint distanceDecrease; // how much to shrink each layer
        uint minCount;         // starting petal count on first layer
        uint countIncrease;    // how much to increase petal count each layer
        uint maxRadius;        // starting petal size on first layer
        uint radiusDecrease;   // how much to decrease the radius each layer
        uint levels;           // how many layers 
        uint petalSeed;        // seed storing what types of petals are on each layer
        Mutation mutation;     // what "Mutation" this flower has
        bool bg;               // whether or not this flower has a background
    }

    /// @notice this struct packs details for each layer to avoid stack-too-deep errors
    struct LayerDeets {
        uint distance;
        uint count;
        uint countEvened;
        uint radius;
        bool glow;
    }

    enum Interval {MONO, ANALAGOUS, TERTIARY, TRIADIC}
    uint constant NUM_MUTATIONS = 4;
    enum Mutation {NONE, BIO, VEINS, ALBINO}

    /// UTILITY FUNCTIONS
    /// @notice convert a byte to a number between min and max
    function randomValue(bytes1 seed, uint min, uint max) internal pure returns (uint value){
        uint percent = (100* (1 + uint32(uint8(seed)))) / 256;
        value = min + ((percent * (max - min)) / 100);
    }

    /// @notice the corehue is constant between the buds and the flowers, and is based on tokenId
    function getCoreHueFromTokenId(uint tokenId) internal view returns (uint) {
        bytes32 seed = keccak256(abi.encodePacked(tokenId));
        uint hue = uint(uint8(seed[0])) * uint(uint8(seed[10])) % 360;
        return hue % 360;
    }

    /// @notice convert hue, saturation, and lightness values to an HSL(x,y,z) string
    function getColor(uint _h, uint _s, uint _l) internal pure returns (bytes memory color) {
        color = abi.encodePacked("hsl(", _h.toString(), ", ", _s.toString(), "%, ", _l.toString(), "%)");
    }

    /// @notice return strings for each mutation, for attribute metadata
    function getMutationNames() internal pure returns(string[NUM_MUTATIONS] memory) {
        return ["None", "Bioluminescence", "Veins", "Albino"];
    }

    /// @notice each mutation has an opacity override
    function getMutationOpacity(Palette memory _p) internal pure returns(uint) {
        uint[NUM_MUTATIONS] memory opacities = [_p.opacity, 50, 30, 100];
        return opacities[uint(_p.mutation)];
    }

    /// @notice these are color intervals, in terms of degrees in the color wheel 
    function getIntervals() internal pure returns(uint8[4] memory) {
        return [0, 15, 60, 120];
    }

    /// FLOWER DESIGN

    /// @notice given a random seed and tokenId, generate all traits of the flower.
    function getFlowerTraits(uint _seed, uint tokenId) internal view returns (FlowerTraits memory f) {
        bytes32 seed = keccak256(abi.encodePacked(_seed, tokenId));
        
        uint h1 = getCoreHueFromTokenId(tokenId);
        uint s = 1; //the seed indexes could be hard-coded but tracking it with this variable makes coding much easier
        uint l = randomValue(seed[s++], 50, 70);
        uint maxDistance = randomValue(seed[s++], 250, 300);
        uint levels = randomValue(seed[s++], 2, 6);
        uint minCount = randomValue(seed[s++], 2, 6) * 2;
        Mutation mutation = randomValue(seed[s++], 0, 100) < 10 ? Mutation(randomValue(seed[s++], 0, NUM_MUTATIONS)) : Mutation.NONE;

        return FlowerTraits(
            Palette(
                h1,       // hue1
                (h1 + 10 + randomValue(seed[s++], 0, 20)) % 360, // hue2
                mutation == Mutation.BIO ? 100 : randomValue(seed[s++], 40, 80), // saturation
                l,        // lightness
                l < 60 && uint8(seed[s++]) < 180, // lwalk
                uint8(seed[s++]) < 120 ? 1 : randomValue(seed[s++], 2, 4), // cycle
                Interval(randomValue(seed[s++], 0, 4)), // interval
                mutation == Mutation.BIO ? 50 : randomValue(seed[s++], 50, 100), // opacity
                mutation//mutation == Mutation.VEINS || mutation == Mutation.ALBINO// stroked
            ), 
            maxDistance,   // maxDistance
            (maxDistance - randomValue(seed[s++], 80, 120)) / levels, // distanceDecrease
            minCount,      // min Count
            minCount == 4 ? randomValue(seed[s++], 4, 6) : randomValue(seed[s++], 1, 6),   // count increase
            randomValue(seed[s++], 150, 200),   // max width
            randomValue(seed[s++], 70, 90),     // width decrease
            levels,                             // levels
            uint(uint8(seed[s++])),             // petalSeed
            mutation,
            randomValue(seed[s++], 0, 100) < 50 // bg color
        );
    }

    function getAttributes(FlowerTraits memory _traits) internal pure returns (bytes memory attributeBytes) {
        (string[NUM_ATTRIBUTES] memory names, string[NUM_ATTRIBUTES] memory values) = getTraitNamesAndValues(_traits);
        return generateAttributeMetadata(names, values);
    }

    /// @notice generate the metadata strings and store in two arrays
    function getTraitNamesAndValues(FlowerTraits memory _traits) internal pure returns (string[NUM_ATTRIBUTES] memory names, string[NUM_ATTRIBUTES] memory values) {
        names = ["Base Color", "Levels", "Background Color", "Mutation"];
        values[0] = _traits.palette.h1.toString();              // Base Color
        values[1] = _traits.levels.toString();                  // Levels
        values[2] = _traits.bg ? "Color" : "None";              // Background Color
        values[3] = getMutationNames()[uint(_traits.mutation)]; // Mutation names
    }

    /// @notice helper function to pack metadata into a single string
    function generateAttributeMetadata(string[NUM_ATTRIBUTES] memory names, string[NUM_ATTRIBUTES] memory values) internal pure returns (bytes memory attributeMetadata) {
        attributeMetadata = abi.encodePacked("[");
        for (uint i = 0; i < names.length - 1; i++) {
            attributeMetadata = abi.encodePacked(attributeMetadata,
                '{"trait_type":"', names[i], '",',
                '"value":"', values[i], '"},');
        }

        attributeMetadata = abi.encodePacked(attributeMetadata,
                '{"trait_type":"', names[names.length - 1], '",',
                '"value":"', values[names.length - 1], '"}]');
    }

    /// @notice perform color math to turn palette traits into a specific petal's color
    function getColorFromPalette(Palette memory _p, uint _h, uint _index) internal pure returns (bytes memory) {
        uint h = (_h == 1) ? _p.h1 : _p.h2;
        h += (_index % _p.cycle) * getIntervals()[uint(_p.interval)];
        uint l = _p.lwalk ? _p.l + (_index * 7) : _p.l;
        return getColor(
            h, _p.s, l
        );
    }

    /// @notice return the bud SVG with the color injected.
    function getBudArt(uint tokenId) external view returns (bytes memory budBytes) {
        return abi.encodePacked(
            "data:image/svg+xml;base64,",
            Base64.encode(
                abi.encodePacked(
                    BUD_STUB_1, 
                    "hsl(", getCoreHueFromTokenId(tokenId).toString(), ",80%,60%",
                    BUD_STUB_2)
            )
        );
    }

    /// @notice pack the art into a single base64 encoded SVG. Can return with or without animations.
    function packArt(bytes memory flowerBytes, bool animated, bytes memory bg) internal pure returns (bytes memory) {
        
        return abi.encodePacked(
            "data:image/svg+xml;base64,",
            Base64.encode(
                abi.encodePacked(
                    '<svg width="100%" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" id="thesvg" viewBox="-700 -700 1400 1400" ',
                    'style="background-color: ', bg,'">',
                    '<style>',
                    animated ? FLOWER_ANIMATIONS : abi.encodePacked(""),
                    '</style>',
                    flowerBytes, 
                    "</svg>"
                )
            )
        );
    }

    function getBGColor(FlowerTraits memory _traits) internal pure returns (bytes memory bgcolorbytes) {
        if (_traits.mutation == Mutation.BIO) {
            return abi.encodePacked("#000");
        }
        else if (_traits.bg) {
            uint hue = (_traits.palette.h1 + 180 + getIntervals()[uint(_traits.palette.interval)]) % 360;
            return abi.encodePacked("hsl(", hue.toString(), ",40%,60%)");
        }
        else {
            return abi.encodePacked("#FFF");
        }
    }

    function getFlowerArt(uint _seed, uint tokenId) external view returns (bytes memory still, bytes memory animated, bytes memory attributes) {
        bytes memory flowerBytes = FLOWER_DEFS;
        FlowerTraits memory _traits = getFlowerTraits(_seed, tokenId);
        bytes[] memory layers = getFlowerLayers(_traits);
        for (uint i = 0; i < layers.length; i++) {
            flowerBytes = abi.encodePacked(flowerBytes, layers[i]);
        }
        bytes memory bg = getBGColor(_traits);
        return (packArt(flowerBytes, false, bg), packArt(flowerBytes, true, bg), getAttributes(_traits));
    }

    /// FLOWER CONSTRUCTION

    /// @notice rounds down petal radii to avoid petals being too large around top layer
    function getAdjustedRadius(LayerDeets memory _deets) internal pure returns (uint) {
        uint maximumRadius = ((_deets.distance * 2 * 314) / 100) / _deets.countEvened;
        return maximumRadius < _deets.radius ? maximumRadius : _deets.radius;
    }

    /// @notice main construction function. Takes the flower traits and generates each layer
    function getFlowerLayers(FlowerTraits memory _traits) internal pure returns (bytes[] memory layers) {
        layers = new bytes[](_traits.levels + 1);
        LayerDeets memory deets = LayerDeets(
                                    _traits.maxDistance, 
                                    _traits.minCount,
                                    _traits.minCount,
                                    _traits.maxRadius,
                                    _traits.mutation == Mutation.BIO);

        for (uint i = 0; i < _traits.levels; i++) {
            layers[i] = createLayer(i, _traits.petalSeed, deets, _traits.palette);

            deets.distance -= _traits.distanceDecrease;
            deets.count += _traits.countIncrease;
            deets.countEvened = (deets.count / 2) * 2;
            deets.radius = (deets.radius * _traits.radiusDecrease) / 100;
        }
        layers[layers.length - 1] = createCore(deets.distance + _traits.distanceDecrease, _traits.palette, _traits.levels - 1);
        return layers;
    }

    /// @notice creates a given flower layer. Each layer is actually two layers of petals of the same type
    function createLayer(uint _index, uint _typeSeed, LayerDeets memory _deets, Palette memory _p) internal pure returns (bytes memory layerBytes) {
        
        layerBytes = abi.encodePacked(
            "<g style='transform: rotate(0deg) scale(100%); animation: scaleUp 8s cubic-bezier(.24,.95,.6,1) both ",
             (_index * 200).toString(), "ms'>",
            _deets.glow && _index == 0 ? "<g filter='url(#glow)'>" : "<g filter='url(#shadow)'>");
        uint8 petalType = uint8(keccak256(abi.encodePacked(_typeSeed))[_index]);
        uint rotationInterval = 36000 / _deets.countEvened;

        for (uint i = 0; i < _deets.countEvened; i+= 2) {
            bytes memory color = getColorFromPalette(_p, 1, _index);
            layerBytes = abi.encodePacked(
                layerBytes, 
                createPetal(
                    _p,
                    petalType,
                    _deets.distance + 5,
                    (i * rotationInterval) / 100,// (_index % 2 == 1 ? i * rotationInterval + (rotationInterval / 2): i * rotationInterval) / 100,
                    getAdjustedRadius(_deets) + 5, 
                    color));
        }

        layerBytes = abi.encodePacked(
            layerBytes, 
            "</g></g><g style='transform: rotate(0deg) scale(100%); animation: scaleUp 8s cubic-bezier(.24,.95,.6,1) both ",
             (_index * 200).toString(), "ms'>",
            _deets.glow && _index == 0 ? "<g filter='url(#glow)'>" : "<g filter='url(#shadow)'>");
        
        for (uint i = 1; i < _deets.countEvened; i+= 2) {
            bytes memory color = getColorFromPalette(_p, 2, _index);
            layerBytes = abi.encodePacked(
                layerBytes, 
                createPetal(
                    _p,
                    petalType,
                    _deets.distance - 5, 
                    (i * rotationInterval) / 100,//(_index % 2 == 1 ? i * rotationInterval + (rotationInterval / 2): i * rotationInterval) / 100,
                    getAdjustedRadius(_deets) - 5, 
                    color));
        }
        layerBytes = abi.encodePacked(layerBytes, "</g></g>");
    }

    /// @notice each petal has some basic attributes that are the same regardless of petal type
    function getBasicPetalAttributes(Palette memory _p, bytes memory _hue) internal pure returns (bytes memory petalBytes) {
        return abi.encodePacked(
                '" stroke="', _p.mutation == Mutation.ALBINO ? abi.encodePacked("black") : _hue,
                '" fill="', _p.mutation == Mutation.ALBINO ? abi.encodePacked("white") : _hue,
                '" fill-opacity="', getMutationOpacity(_p).toString() , "%"
        );
    }

    /// @notice create the petal. there are three types of petals, each of which are created slightly differently
    function createPetal(Palette memory _p, uint8 _type, uint _distance, uint _rotation, uint _radius, bytes memory _hue) internal pure returns (bytes memory petalBytes) {
        if (_type <  85) { // CIRCLE
            petalBytes = abi.encodePacked(
                '<circle cy="', _distance.toString(), 
                '" r="', _radius.toString(),
                '" stroke-width="', _p.mutation == Mutation.VEINS || _p.mutation == Mutation.ALBINO ? "10px" : "0px",
                getBasicPetalAttributes(_p, _hue),
                '" style="transform: rotate(', _rotation.toString(), 'deg)" />'
            );
        }
        else if (_type < 170) { // ELLIPSE
            petalBytes = abi.encodePacked(
                '<ellipse cy="', _distance.toString(), 
                '" rx="', ((_radius * 80)/100).toString(),
                '" ry="', ((_radius * 150)/100).toString(),
                '" stroke-width="', _p.mutation == Mutation.VEINS || _p.mutation == Mutation.ALBINO ? "10px" : "0px",
                getBasicPetalAttributes(_p, _hue),
                '" style="transform: rotate(', _rotation.toString(), 'deg)" />'
            );
        }
        else {
            uint scale = ((100 * _radius) / 180);// needs two decimal places

            petalBytes = abi.encodePacked( // POINTY
                '<path d="M 0 300 C 0 300 -150 240 -170 170 C -220 0 0 -300 0 -300 C 0 -300 220 0 170 170 C 150 240 0 300 0 300 Z', 
                '" stroke-width="', abi.encodePacked((_p.mutation == Mutation.VEINS || _p.mutation == Mutation.ALBINO ? (1000 / scale) : 0).toString(), "px"),
                getBasicPetalAttributes(_p, _hue),
                '" style="transform: rotate(', _rotation.toString(),
                     'deg) translate(0px, -', _distance.toString(), 
                     'px) scale(', scale.toString(), '%)"/>'
            );
        }
    }

    /// @notice create the "core" of the flower, the circle in the center. 
    function createCore(uint _radius, Palette memory _p, uint _index) internal pure returns (bytes memory coreBytes) {
        bytes memory id = abi.encodePacked(_p.h1.toString(), _p.h2.toString()); //abi.encodePacked(hue1, "-", hue2);
        coreBytes = abi.encodePacked(
            "<radialGradient id='", id,"'>",
                "<stop offset='0%' stop-color='", getColor(_p.h1, _p.s, _p.l), "'/>",
                "<stop offset='100%' stop-color='", getColor(_p.h2, _p.s, _p.l - 30), "'/>",
            "</radialGradient>",
            "<g style='transform: rotate(0deg) scale(100%); animation: scaleUp 8s cubic-bezier(.24,.95,.6,1) both ",
             (_index * 200).toString(), "ms'>",
            "<circle r='", _radius.toString(), 
            "' filter='url(#shadow)'",
            " stroke='", _p.mutation == Mutation.ALBINO ? abi.encodePacked("black") : getColorFromPalette(_p, 0, _index),
            "' stroke-width='", _p.mutation == Mutation.ALBINO ? "10px" : "0px",
            "' fill-opacity='", (_p.mutation == Mutation.ALBINO ? "100" : (_p.opacity + 25).toString()), "%'",
            " fill='", _p.mutation == Mutation.ALBINO ? abi.encodePacked("white") : abi.encodePacked("url(#", id, ")"), 
            
            "'/></g>"
        );
    }

}