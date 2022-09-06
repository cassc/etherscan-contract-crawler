// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Trinket Test
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//          _----------_,          //
//        ,"__         _-:,        //
//       /    ""--_--""...:\       //
//      /         |.........\      //
//     /          |..........\     //
//    /,         _'_........./:    //
//    ! -,    _-"   "-_... ,;;:    //
//    \   -_-"         "-_/;;;;    //
//     \   \             /;;;;'    //
//      \   \           /;;;;      //
//       '.  \         /;;;'       //
//         "-_\_______/;;'         //
//                                 //
//                                 //
/////////////////////////////////////


contract TRKT is ERC721Creator {
    constructor() ERC721Creator("Trinket Test", "TRKT") {}
}