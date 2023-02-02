// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RGB Ready Give Back
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//     _______    ______   _______      //
//    |       \  /      \ |       \     //
//    | $$$$$$$\|  $$$$$$\| $$$$$$$\    //
//    | $$__| $$| $$ __\$$| $$__/ $$    //
//    | $$    $$| $$|    \| $$    $$    //
//    | $$$$$$$\| $$ \$$$$| $$$$$$$\    //
//    | $$  | $$| $$__| $$| $$__/ $$    //
//    | $$  | $$ \$$    $$| $$    $$    //
//     \$$   \$$  \$$$$$$  \$$$$$$$     //
//                                      //
//                                      //
//                                      //
//                                      //
//                                      //
//////////////////////////////////////////


contract RGB is ERC721Creator {
    constructor() ERC721Creator("RGB Ready Give Back", "RGB") {}
}