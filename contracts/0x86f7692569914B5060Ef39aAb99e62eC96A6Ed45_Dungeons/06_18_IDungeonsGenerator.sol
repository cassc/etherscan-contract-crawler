// SPDX-License-Identifier: GPL-3.0

/// @title Interface for dungeon generation

/*****************************************************
0000000                                        0000000
0001100  Crypts and Caverns                    0001100
0001100     9000 generative on-chain dungeons  0001100
0003300                                        0003300
*****************************************************/

pragma solidity ^0.8.0;

interface IDungeonsGenerator {

    struct EntityData {
        uint8 x;
        uint8 y;
        uint8 entityType;
    }

    function getLayout(uint256 seed, uint256 size) external view returns (bytes memory, uint8);
    function getEntities(uint256 seed, uint256 size) external view returns (uint8[] memory, uint8[] memory, uint8[] memory);
    function getEntitiesBytes(uint256 seed, uint256 size) external view returns (bytes memory, bytes memory);
    function getPoints(uint256 seed, uint256 size) external view returns (bytes memory, uint256);
    function getDoors(uint256 seed, uint256 size) external view returns (bytes memory, uint256);
    function countEntities(uint8[] memory entities) external pure returns(uint256, uint256);
}