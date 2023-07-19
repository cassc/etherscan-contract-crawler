// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITerraformsSVG {
    struct SVGParams {
        uint[32][32] heightmapIndices;
        uint level;
        uint tile;
        uint resourceLvl;
        uint resourceDirection;
        uint status;
        uint font;
        uint fontSize;
        uint charsIndex;
        string zoneName;
        string[9] chars;
        string[10] zoneColors;
    }

    struct AnimParams {
        Activation activation; // Token's animation type
        uint classesAnimated; // Classes animated
        uint duration; // Base animation duration for first class
        uint durationInc; // Duration increment for each class
        uint delay; // Base delay for first class
        uint delayInc; // Delay increment for each class
        uint bgDuration; // Animation duration for background
        uint bgDelay; // Delay for background
        string easing; // Animation mode, e.g. steps(), linear, ease-in-out
        string[2] altColors;
    }

    enum Activation {Cascade, Plague}
    
    function makeSVG(SVGParams memory, AnimParams memory) 
        external 
        view 
        returns (string memory, string memory, string memory);
}

interface ITerraformsZones {
    function tokenZone(uint index) 
        external 
        view 
        returns (string[10] memory, string memory);
}

interface ITerraformsCharacters {
    function characterSet(uint index) 
        external 
        view 
        returns (string[9] memory, uint);

    function font(uint id) 
        external 
        view 
        returns (string memory);
}

interface IPerlinNoise {
    function noise3d(int256, int256, int256) external view returns (int256);
}

interface ITerraformsResource {
    function amount(uint) external view returns (uint);
}