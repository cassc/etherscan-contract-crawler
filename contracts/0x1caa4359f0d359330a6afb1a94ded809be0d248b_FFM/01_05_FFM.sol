// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fast Food Memes
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////
//                              //
//                              //
//      _____  _____            //
//    _/ ____\/ ____\_____      //
//    \   __\\   __\/     \     //
//     |  |   |  | |  Y Y  \    //
//     |__|   |__| |__|_|  /    //
//                       \/     //
//                              //
//                              //
//////////////////////////////////


contract FFM is ERC1155Creator {
    constructor() ERC1155Creator("Fast Food Memes", "FFM") {}
}