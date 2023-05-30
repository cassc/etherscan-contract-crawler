// SPDX-License-Identifier: GPL-3.0

/// @title Rendering code to draw an svg of the dungeon

/*****************************************************
0000000                                        0000000
0001100  Crypts and Caverns                    0001100
0001100     9000 generative on-chain dungeons  0001100
0003300                                        0003300
*****************************************************/

pragma solidity ^0.8.0;

import { IDungeons } from './IDungeons.sol';

interface IDungeonsRender {

    function draw(IDungeons.Dungeon memory dungeon, uint8[] memory x, uint8[] memory y, uint8[] memory entityData) external view returns (string memory);
    function tokenURI(uint256 tokenId, IDungeons.Dungeon memory dungeon, uint256[] memory entities) external view returns(string memory);
}