// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: COMBS & CLIPS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//                                         //
//                                         //
//                                         //
//                                         //
//                    ,---,                //
//                ,-+-. /  |               //
//       ,---.   ,--.'|'   |   ,---.       //
//      /     \ |   |  ,"' |  /     \      //
//     /    / ' |   | /  | | /    / '      //
//    .    ' /  |   | |  | |.    ' /       //
//    '   ; :__ |   | |  |/ '   ; :__      //
//    '   | '.'||   | |--'  '   | '.'|     //
//    |   :    :|   |/      |   :    :     //
//     \   \  / '---'        \   \  /      //
//      `----'                `----'       //
//                                         //
//                                         //
//                                         //
/////////////////////////////////////////////


contract CNC is ERC721Creator {
    constructor() ERC721Creator("COMBS & CLIPS", "CNC") {}
}