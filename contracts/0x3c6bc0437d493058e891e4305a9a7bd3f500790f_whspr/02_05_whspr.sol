// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Whispers
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//                      //
//         /\*\         //
//        /\O\*\        //
//       /*/\/\/\       //
//      /\O\/\*\/\      //
//     /\*\/\*\/\/\     //
//    /\O\/\/*/\/O/\    //
//          ||          //
//          ||          //
//          ||          //
//                      //
//                      //
//////////////////////////


contract whspr is ERC721Creator {
    constructor() ERC721Creator("Whispers", "whspr") {}
}