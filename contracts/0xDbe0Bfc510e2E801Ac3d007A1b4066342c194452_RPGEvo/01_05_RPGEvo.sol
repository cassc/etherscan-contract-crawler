// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Smol RPG Party Evolution
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//          /\              //
//         / *\             //
//        / *  \            //
//      ----------          //
//       | 0   0|           //
//       |______| - Smol    //
//                          //
//                          //
//////////////////////////////


contract RPGEvo is ERC721Creator {
    constructor() ERC721Creator("Smol RPG Party Evolution", "RPGEvo") {}
}