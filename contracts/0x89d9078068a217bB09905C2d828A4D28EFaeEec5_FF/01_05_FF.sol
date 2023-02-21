// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FiFi
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//                              //
//    ███████╗██╗███████╗██╗    //
//    ██╔════╝██║██╔════╝██║    //
//    █████╗  ██║█████╗  ██║    //
//    ██╔══╝  ██║██╔══╝  ██║    //
//    ██║     ██║██║     ██║    //
//    ╚═╝     ╚═╝╚═╝     ╚═╝    //
//                              //
//                              //
//                              //
//                              //
//////////////////////////////////


contract FF is ERC721Creator {
    constructor() ERC721Creator("FiFi", "FF") {}
}