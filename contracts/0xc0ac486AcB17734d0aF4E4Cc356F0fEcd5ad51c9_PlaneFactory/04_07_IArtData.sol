// File: contracts/IArtData.sol


// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./IArtData.sol";

interface IArtData{

    struct ArtProps {
        uint256 numOfX;
        uint256 numOfY;
        uint256 numAngles;
        uint256 numTypes;
        uint256[] extraParams;
    }

    function getProps() external view returns(ArtProps memory);


    function getNumOfX() external view returns (uint) ;

    function getNumOfY() external view returns (uint);

    function getNumAngles() external view returns (uint);

    function getNumTypes() external view returns (uint);

    function getNumSpeeds() external view returns (uint);

    function getSkyName(uint index) external view returns (string calldata);

    function getNumSkyCols() external view returns (uint);

    function getColorPaletteName(uint paletteIdx) external view returns (string calldata) ;

    function getNumColorPalettes() external view returns (uint) ;

    function getPaletteSize(uint paletteIdx) external view returns (uint);

    function getProximityName(uint index) external view returns (string calldata);

    function getNumProximities() external view returns (uint);

    function getMaxNumPlanes() external view returns (uint);


    function getLevelRarities() external view returns (uint8[] calldata);

    function getSpeedRarities() external view returns (uint8[] calldata);

    function getPlaneTypeRarities() external view returns (uint8[] calldata);

    function getProximityRarities() external view returns (uint8[] calldata);

    function getSkyRarities() external view returns (uint8[] calldata) ;

    function getColorPaletteRarities() external view returns (uint8[] calldata) ;

}