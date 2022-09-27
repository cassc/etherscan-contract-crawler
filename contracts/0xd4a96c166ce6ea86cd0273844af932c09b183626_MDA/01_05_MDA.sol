// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Metaverse Digital Assets
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//                                   //
//    ███╗   ███╗██████╗  █████╗     //
//    ████╗ ████║██╔══██╗██╔══██╗    //
//    ██╔████╔██║██║  ██║███████║    //
//    ██║╚██╔╝██║██║  ██║██╔══██║    //
//    ██║ ╚═╝ ██║██████╔╝██║  ██║    //
//    ╚═╝     ╚═╝╚═════╝ ╚═╝  ╚═╝    //
//                                   //
//                                   //
//                                   //
//                                   //
//                                   //
//                                   //
//                                   //
//                                   //
//                                   //
//                                   //
//                                   //
///////////////////////////////////////


contract MDA is ERC721Creator {
    constructor() ERC721Creator("Metaverse Digital Assets", "MDA") {}
}