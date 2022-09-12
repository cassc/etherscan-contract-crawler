// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Black and White Mojo
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//                              _            //
//       ____ ___   ____       (_)  ____     //
//      / __ `__ \ / __ \     / /  / __ \    //
//     / / / / / // /_/ /    / /  / /_/ /    //
//    /_/ /_/ /_/ \____/  __/ /   \____/     //
//                       /___/               //
//                                           //
//                                           //
///////////////////////////////////////////////


contract BWMO is ERC721Creator {
    constructor() ERC721Creator("Black and White Mojo", "BWMO") {}
}