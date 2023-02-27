// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Medieval Smols
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


contract MEDSMOL is ERC721Creator {
    constructor() ERC721Creator("Medieval Smols", "MEDSMOL") {}
}