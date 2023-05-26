// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Uncommon 1/1s
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//                        //
//    ██╗░██╗░███████╗    //
//    ╚═╝██╔╝██╔██╔══╝    //
//    ░░██╔╝░╚██████╗░    //
//    ░██╔╝░░░╚═██╔██╗    //
//    ██╔╝██╗███████╔╝    //
//    ╚═╝░╚═╝╚══════╝░    //
//                        //
//                        //
////////////////////////////


contract UNC is ERC721Creator {
    constructor() ERC721Creator("Uncommon 1/1s", "UNC") {}
}