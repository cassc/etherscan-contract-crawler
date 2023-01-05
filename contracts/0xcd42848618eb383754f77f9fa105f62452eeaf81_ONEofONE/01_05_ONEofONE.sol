// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ART by OVACHINSKY
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////
//                                                                        //
//                                                                        //
//                                                                        //
//       _____     ___    ____ _____                                      //
//      / _ \ \   / / \  |  _ \_   _|                                     //
//     | | | \ \ / / _ \ | |_) || |                                       //
//     | |_| |\ V / ___ \|  _ < | |                                       //
//      \___/  \_/_/   \_\_| \_\|_|                                       //
//                                                                        //
//    Artistic creations made by yours truly.                             //
//                                                                        //
//    Original, unique, extraordinary, complex, simple, cheap, shitty.    //
//    It all depends on who you ask.                                      //
//                                                                        //
//                                                                        //
////////////////////////////////////////////////////////////////////////////


contract ONEofONE is ERC721Creator {
    constructor() ERC721Creator("ART by OVACHINSKY", "ONEofONE") {}
}