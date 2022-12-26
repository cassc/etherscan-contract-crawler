// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nostalgic Toy World
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//    ███╗   ██╗████████╗██╗    ██╗    //
//    ████╗  ██║╚══██╔══╝██║    ██║    //
//    ██╔██╗ ██║   ██║   ██║ █╗ ██║    //
//    ██║╚██╗██║   ██║   ██║███╗██║    //
//    ██║ ╚████║   ██║   ╚███╔███╔╝    //
//    ╚═╝  ╚═══╝   ╚═╝    ╚══╝╚══╝     //
//                                     //
//                                     //
/////////////////////////////////////////


contract NTW is ERC721Creator {
    constructor() ERC721Creator("Nostalgic Toy World", "NTW") {}
}