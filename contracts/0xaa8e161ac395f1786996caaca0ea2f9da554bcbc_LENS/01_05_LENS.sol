// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Incredibly Clear Lenses
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//                                          //
//    ██╗     ███████╗███╗   ██╗███████╗    //
//    ██║     ██╔════╝████╗  ██║██╔════╝    //
//    ██║     █████╗  ██╔██╗ ██║███████╗    //
//    ██║     ██╔══╝  ██║╚██╗██║╚════██║    //
//    ███████╗███████╗██║ ╚████║███████║    //
//    ╚══════╝╚══════╝╚═╝  ╚═══╝╚══════╝    //
//                                          //
//                                          //
//                                          //
//                                          //
//////////////////////////////////////////////


contract LENS is ERC721Creator {
    constructor() ERC721Creator("Incredibly Clear Lenses", "LENS") {}
}