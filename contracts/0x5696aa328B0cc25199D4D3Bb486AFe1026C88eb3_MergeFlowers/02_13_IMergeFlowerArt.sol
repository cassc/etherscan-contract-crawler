// SPDX-License-Identifier: MIT
// Copyright (c) 2022 Lawrence X. Rogers
pragma solidity ^0.8.9;

interface IMergeFlowerArt {
    
    enum Interval {MONO, ANALAGOUS, TERTIARY, TRIADIC}

    struct Palette {
        uint h1;
        uint h2;
        uint s;
        uint l;
        bool lwalk;
        uint cycle;
        Interval interval;
        uint opacity;
    }

    struct FlowerTraits {
        Palette palette;
        uint maxDistance;
        uint distanceDecrease;
        uint minCount;
        uint countIncrease;
        uint maxRadius;
        uint radiusDecrease;
        uint levels;
        uint petalSeed;
    }

    struct LayerDeets {
        uint distance;
        uint countWithDigits;
        uint count;
        uint radius;
    }

    function getBudArt(uint tokenId) external view returns (bytes memory budBytes);
    function getFlowerArt(uint _seed, uint tokenId) external view returns (bytes memory still, bytes memory animated, bytes memory attributes);
}