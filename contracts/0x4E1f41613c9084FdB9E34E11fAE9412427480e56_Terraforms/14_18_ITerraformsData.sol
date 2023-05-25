// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITerraformsData {
    function tokenURI(uint, uint, uint, uint, uint, uint[] memory) 
        external 
        view 
        returns (string memory);

    function tokenHTML(uint, uint, uint, uint, uint[] memory) 
        external 
        view 
        returns (string memory);

    function tokenSVG(uint, uint, uint, uint, uint[] memory) 
        external 
        view 
        returns (string memory);

    function tokenTerrain(uint, uint, uint) 
        external 
        view 
        returns (int[32][32] memory);

    function tokenCharacters(uint, uint, uint, uint, uint[] memory) 
        external 
        view 
        returns (string[32][32] memory);

    function tokenHeightmapIndices(uint, uint, uint, uint, uint[] memory) 
        external 
        view 
        returns (uint[32][32] memory);

    function tokenZone(uint, uint) 
        external 
        view 
        returns (string[10] memory, string memory);

    function characterSet(uint, uint) 
        external 
        view 
        returns (string[9] memory, uint, uint, uint);
    
    function levelAndTile(uint, uint) external view returns (uint, uint);
    
    function tileOrigin(uint, uint, uint, uint, uint) 
        external 
        view 
        returns (int, int, int);
   
    function levelDimensions(uint) external view returns (uint);

    function tokenElevation(uint, uint, uint) external view returns (int);

    function prerevealURI(uint) external view returns (string memory);
}