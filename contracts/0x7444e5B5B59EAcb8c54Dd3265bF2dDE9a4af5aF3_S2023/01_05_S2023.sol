// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Smols 2023 Open Edition
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


contract S2023 is ERC721Creator {
    constructor() ERC721Creator("Smols 2023 Open Edition", "S2023") {}
}