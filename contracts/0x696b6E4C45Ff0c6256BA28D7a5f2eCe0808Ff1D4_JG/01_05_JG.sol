// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Jonai Gallery
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    ╭────────────────────╮    //
//    │                    │    //
//    │       Jonai        │    //
//    │      Gallery       │    //
//    │                    │    //
//    │                    │    //
//    │                    │    //
//    ╰────────────────────╯    //
//                              //
//                              //
//                              //
//////////////////////////////////


contract JG is ERC721Creator {
    constructor() ERC721Creator("Jonai Gallery", "JG") {}
}