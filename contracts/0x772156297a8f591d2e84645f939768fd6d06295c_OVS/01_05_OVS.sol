// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OBSIDIAN VISIONS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//                                         //
//    .▄▄ · ▄• ▄▌ ▐ ▄  ▄▄▄·  ▄▄ • ▄▄▄ .    //
//    ▐█ ▀. █▪██▌•█▌▐█▐█ ▀█ ▐█ ▀ ▪▀▄.▀·    //
//    ▄▀▀▀█▄█▌▐█▌▐█▐▐▌▄█▀▀█ ▄█ ▀█▄▐▀▀▪▄    //
//    ▐█▄▪▐█▐█▄█▌██▐█▌▐█ ▪▐▌▐█▄▪▐█▐█▄▄▌    //
//     ▀▀▀▀  ▀▀▀ ▀▀ █▪ ▀  ▀ ·▀▀▀▀  ▀▀▀     //
//                                         //
//                                         //
//                                         //
/////////////////////////////////////////////


contract OVS is ERC721Creator {
    constructor() ERC721Creator("OBSIDIAN VISIONS", "OVS") {}
}