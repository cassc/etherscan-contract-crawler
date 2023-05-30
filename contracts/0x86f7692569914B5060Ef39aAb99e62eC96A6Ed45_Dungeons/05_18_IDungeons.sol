// SPDX-License-Identifier: GPL-3.0

/// @title Interface for Crypts and Caverns

/*****************************************************
0000000                                        0000000
0001100  Crypts and Caverns                    0001100
0001100     9000 generative on-chain dungeons  0001100
0003300                                        0003300
*****************************************************/

pragma solidity ^0.8.0;

interface IDungeons {
    struct Dungeon {
        uint8 size;
        uint8 environment;
        uint8 structure;  // crypt or cavern
        uint8 legendary;
        bytes layout;
        EntityData entities;
        string affinity;
        string dungeonName;
    }

    struct EntityData {
        uint8[] x;
        uint8[] y;
        uint8[] entityType;
    }

    function claim(uint256 tokenId) external payable;
    function claimMany(uint256[] memory tokenArray) external payable;
    function ownerClaim(uint256 tokenId) external payable;
    function mint() external payable;
    function openClaim() external;
    function withdraw(address payable recipient, uint256 amount) external;
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function getLayout(uint256 tokenId) external view returns (bytes memory);
    function getSize(uint256 tokenId) external view returns (uint8);
    function getEntities(uint256 tokenId) external view returns (uint8[] memory, uint8[] memory, uint8[] memory);
    function getEnvironment(uint256 tokenId) external view returns (uint8);
    function getName(uint256 tokenId) external view returns (string memory);
    function getNumPoints(uint256 tokenId) external view returns (uint256);
    function getNumDoors(uint256 tokenId) external view returns (uint256);
    function getSvg(uint256 tokenId) external view returns (string memory);
}