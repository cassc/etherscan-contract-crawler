// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Flight
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                                                                      //
//                                                                                      //
//     ▄▄▄▄▄▄▄▄▄▄▄  ▄            ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄         ▄  ▄▄▄▄▄▄▄▄▄▄▄     //
//    ▐░░░░░░░░░░░▌▐░▌          ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░▌       ▐░▌▐░░░░░░░░░░░▌    //
//    ▐░█▀▀▀▀▀▀▀▀▀ ▐░▌           ▀▀▀▀█░█▀▀▀▀ ▐░█▀▀▀▀▀▀▀▀▀ ▐░▌       ▐░▌ ▀▀▀▀█░█▀▀▀▀     //
//    ▐░▌          ▐░▌               ▐░▌     ▐░▌          ▐░▌       ▐░▌     ▐░▌         //
//    ▐░█▄▄▄▄▄▄▄▄▄ ▐░▌               ▐░▌     ▐░▌ ▄▄▄▄▄▄▄▄ ▐░█▄▄▄▄▄▄▄█░▌     ▐░▌         //
//    ▐░░░░░░░░░░░▌▐░▌               ▐░▌     ▐░▌▐░░░░░░░░▌▐░░░░░░░░░░░▌     ▐░▌         //
//    ▐░█▀▀▀▀▀▀▀▀▀ ▐░▌               ▐░▌     ▐░▌ ▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌     ▐░▌         //
//    ▐░▌          ▐░▌               ▐░▌     ▐░▌       ▐░▌▐░▌       ▐░▌     ▐░▌         //
//    ▐░▌          ▐░█▄▄▄▄▄▄▄▄▄  ▄▄▄▄█░█▄▄▄▄ ▐░█▄▄▄▄▄▄▄█░▌▐░▌       ▐░▌     ▐░▌         //
//    ▐░▌          ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░▌       ▐░▌     ▐░▌         //
//     ▀            ▀▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀         ▀       ▀          //
//                                                                                      //
//                                                                                      //
//                                                                                      //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////


contract FLGHT is ERC721Creator {
    constructor() ERC721Creator("Flight", "FLGHT") {}
}