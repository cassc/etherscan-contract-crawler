// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Merging of Memories
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


contract MEMRY is ERC721Creator {
    constructor() ERC721Creator("Merging of Memories", "MEMRY") {}
}