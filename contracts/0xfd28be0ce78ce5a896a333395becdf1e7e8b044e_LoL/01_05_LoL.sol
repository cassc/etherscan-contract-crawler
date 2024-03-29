// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Layers of Light
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//     ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄       ▄  ▄▄▄▄▄▄▄▄▄▄▄     //
//    ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░▌     ▐░▌▐░░░░░░░░░░░▌    //
//     ▀▀▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀▀▀  ▐░▌   ▐░▌ ▐░█▀▀▀▀▀▀▀█░▌    //
//              ▐░▌▐░▌            ▐░▌ ▐░▌  ▐░▌       ▐░▌    //
//              ▐░▌▐░█▄▄▄▄▄▄▄▄▄    ▐░▐░▌   ▐░█▄▄▄▄▄▄▄█░▌    //
//     ▄▄▄▄▄▄▄▄▄█░▌▐░░░░░░░░░░░▌    ▐░▌    ▐░░░░░░░░░░░▌    //
//    ▐░░░░░░░░░░░▌▐░█▀▀▀▀▀▀▀▀▀    ▐░▌░▌   ▐░█▀▀▀▀▀▀▀▀▀     //
//    ▐░█▀▀▀▀▀▀▀▀▀ ▐░▌            ▐░▌ ▐░▌  ▐░▌              //
//    ▐░█▄▄▄▄▄▄▄▄▄ ▐░█▄▄▄▄▄▄▄▄▄  ▐░▌   ▐░▌ ▐░▌              //
//    ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░▌     ▐░▌▐░▌              //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract LoL is ERC721Creator {
    constructor() ERC721Creator("Layers of Light", "LoL") {}
}