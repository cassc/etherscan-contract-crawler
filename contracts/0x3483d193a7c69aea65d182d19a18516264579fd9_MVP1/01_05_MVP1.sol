// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ModernVintagePhotography 1/1s
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//    Modern Vintage Photography           //
//             ___                         //
//           [|     |=|{)__                //
//            |___|    \/   )              //
//             /|\     /|                  //
//            / | \    | \          MVP    //
//                                         //
//                                         //
/////////////////////////////////////////////


contract MVP1 is ERC721Creator {
    constructor() ERC721Creator("ModernVintagePhotography 1/1s", "MVP1") {}
}