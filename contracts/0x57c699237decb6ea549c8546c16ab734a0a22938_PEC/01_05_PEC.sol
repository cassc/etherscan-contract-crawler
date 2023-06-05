// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pepe cooks
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//      __   __             __                      //
//     /    /  |      /    /    /                   //
//    (___ (___| ___ (___ ( __    ___  ___          //
//        )|   )|   )|    |   )| |   )|___ \   )    //
//     __/ |__/ |  / |__  |__/ | |__/  __/  \_/     //
//                               |           /      //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract PEC is ERC721Creator {
    constructor() ERC721Creator("Pepe cooks", "PEC") {}
}