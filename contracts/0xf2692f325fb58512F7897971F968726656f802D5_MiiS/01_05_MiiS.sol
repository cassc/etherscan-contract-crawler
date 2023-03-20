// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: miis.studio
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//                                 //
//                                 //
//                                 //
//                                 //
//    ███╗   ███╗██╗██╗███████╗    //
//    ████╗ ████║██║██║██╔════╝    //
//    ██╔████╔██║██║██║███████╗    //
//    ██║╚██╔╝██║██║██║╚════██║    //
//    ██║ ╚═╝ ██║██║██║███████║    //
//    ╚═╝     ╚═╝╚═╝╚═╝╚══════╝    //
//                                 //
//                                 //
//                                 //
//                                 //
/////////////////////////////////////


contract MiiS is ERC721Creator {
    constructor() ERC721Creator("miis.studio", "MiiS") {}
}