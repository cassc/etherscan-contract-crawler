// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Capies
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//                                //
//    ░█████╗░░█████╗░██████╗░    //
//    ██╔══██╗██╔══██╗██╔══██╗    //
//    ██║░░╚═╝███████║██████╔╝    //
//    ██║░░██╗██╔══██║██╔═══╝░    //
//    ╚█████╔╝██║░░██║██║░░░░░    //
//    ░╚════╝░╚═╝░░╚═╝╚═╝░░░░░    //
//                                //
//                                //
////////////////////////////////////


contract CAP is ERC721Creator {
    constructor() ERC721Creator("Capies", "CAP") {}
}