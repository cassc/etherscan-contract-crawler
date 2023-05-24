// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Smiley Face
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//                                 //
//                    _ _          //
//                   (_) |         //
//      ___ _ __ ___  _| | ___     //
//     / __| '_ ` _ \| | |/ _ \    //
//     \__ \ | | | | | | |  __/    //
//     |___/_| |_| |_|_|_|\___|    //
//                                 //
//                                 //
//                                 //
//                                 //
//                                 //
//                                 //
//                                 //
//                                 //
/////////////////////////////////////


contract Smile is ERC721Creator {
    constructor() ERC721Creator("Smiley Face", "Smile") {}
}