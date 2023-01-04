// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AURORA
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//                        //
//    ░█████╗░░█████╗░    //
//    ██╔══██╗██╔══██╗    //
//    ███████║███████║    //
//    ██╔══██║██╔══██║    //
//    ██║░░██║██║░░██║    //
//    ╚═╝░░╚═╝╚═╝░░╚═╝    //
//                        //
//                        //
////////////////////////////


contract AA is ERC721Creator {
    constructor() ERC721Creator("AURORA", "AA") {}
}