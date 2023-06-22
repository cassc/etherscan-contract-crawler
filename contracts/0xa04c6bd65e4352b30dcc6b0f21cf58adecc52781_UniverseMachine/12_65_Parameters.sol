// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Bezier.sol";
import "./Star.sol";

struct Parameters {

    uint32 whichMasterSet;
    int32 whichColor;
    int32 endIdx;
    int32 cLen;

    uint8[] myColorsR;
    uint8[] myColorsG;
    uint8[] myColorsB;

    int32[] whichTex;
    int32[] whichColorFlow;
    int32[] whichRot;
    int32[] whichRotDir;       
    
    Vector2[] gridPoints;

    Bezier[] paths;
    uint32 numPaths;

    Star[] starPositions;
}