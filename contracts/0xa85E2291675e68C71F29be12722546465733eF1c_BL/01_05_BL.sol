// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bleak Lights
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////
//                                                                   //
//                                                                   //
//     ____                ____                                      //
//    |    ~.    |        |                  .'.       |    ..''     //
//    |____.'_   |        |______          .''```.     |..''         //
//    |       ~. |        |              .'       `.   |``..         //
//    |_______.' |_______ |___________ .'           `. |    ``..     //
//                                                                   //
//                                                                   //
//                                                                   //
///////////////////////////////////////////////////////////////////////


contract BL is ERC721Creator {
    constructor() ERC721Creator("Bleak Lights", "BL") {}
}