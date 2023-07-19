// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITerraforms {
    enum Status {
        Terrain, 
        Daydream, 
        Terraformed, 
        OriginDaydream, 
        OriginTerraformed
    }

    struct TokenData {
        uint tokenId;
        uint level;
        uint xCoordinate;
        uint yCoordinate;
        int elevation;
        int structureSpaceX;
        int structureSpaceY;
        int structureSpaceZ;
        string zoneName;
        string[10] zoneColors;
        string[9] characterSet;
    }

    function tokenURI(uint) 
        external 
        view 
        returns (string memory);

    function tokenHTML(uint) 
        external 
        view 
        returns (string memory);

    function tokenSVG(uint) 
        external 
        view 
        returns (string memory);

    function tokenSupplementalData(uint)
        external
        view
        returns (TokenData memory result);

    function totalSupply()
        external
        view
        returns (uint256);

    function tokenToPlacement(uint tokenId)
        external
        view
        returns (uint);

    function seed()
        external
        view
        returns (uint);

    function tokenToStatus(uint tokenId)
        external
        view
        returns (Status);
}