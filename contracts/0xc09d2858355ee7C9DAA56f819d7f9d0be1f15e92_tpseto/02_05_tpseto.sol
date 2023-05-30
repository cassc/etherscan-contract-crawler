// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: tpseto
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//       _   _   _   _   _   _      //
//      / \ / \ / \ / \ / \ / \     //
//     ( t | p | s | e | t | o )    //
//      \_/ \_/ \_/ \_/ \_/ \_/     //
//                                  //
//                                  //
//////////////////////////////////////


contract tpseto is ERC721Creator {
    constructor() ERC721Creator("tpseto", "tpseto") {}
}