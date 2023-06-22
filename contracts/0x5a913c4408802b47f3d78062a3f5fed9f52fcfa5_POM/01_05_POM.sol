// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pomeranian Operational Mastery
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//    ██████╗  ██████╗ ███╗   ███╗    //
//    ██╔══██╗██╔═══██╗████╗ ████║    //
//    ██████╔╝██║   ██║██╔████╔██║    //
//    ██╔═══╝ ██║   ██║██║╚██╔╝██║    //
//    ██║     ╚██████╔╝██║ ╚═╝ ██║    //
//    ╚═╝      ╚═════╝ ╚═╝     ╚═╝    //
//                                    //
//                                    //
////////////////////////////////////////


contract POM is ERC721Creator {
    constructor() ERC721Creator("Pomeranian Operational Mastery", "POM") {}
}