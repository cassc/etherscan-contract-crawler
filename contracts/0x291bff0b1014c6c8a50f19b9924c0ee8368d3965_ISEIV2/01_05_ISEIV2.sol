// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Light, Shadow, and Everything InBetween VOL. 2
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//            ___,-----.___            //
//        ,--'             `--.        //
//       /                     \       //
//      /                       \      //
//     |                         |     //
//    |                           |    //
//    |        |~~~~~~~~~|        |    //
//    |        \         /        |    //
//     |        \       /        |     //
//      \        \     /        /      //
//       \        |   |        /       //
//        \       |   |       /        //
//         \      |   |      /         //
//          \     |   |     /          //
//           \____|___| ___/           //
//           )___,-----'___(           //
//           )___,-----'___(           //
//           )___,-----'___(           //
//           )___,-----'___(           //
//           \_____________/           //
//                \___/                //
//                                     //
//                                     //
/////////////////////////////////////////


contract ISEIV2 is ERC721Creator {
    constructor() ERC721Creator("Light, Shadow, and Everything InBetween VOL. 2", "ISEIV2") {}
}