// SPDX-License-Identifier: GPL-3.0

/// @title Interface for generating seed and metadata

/*****************************************************
0000000                                        0000000
0001100  Crypts and Caverns                    0001100
0001100     9000 generative on-chain dungeons  0001100
0003300                                        0003300
*****************************************************/

pragma solidity ^0.8.0;

interface IDungeonsSeeder {
    function getSeed(uint256 tokenId) external view returns(uint256);
    function getSize(uint256 seed) external view returns (uint8);
    function getEnvironment(uint256 seed) external view returns (uint8);
    function getName(uint256 seed) external view returns(string memory, string memory, uint8);
}