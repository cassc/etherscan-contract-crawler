// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SPECIAL EGGDITIONS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//      / \ / \ / \ / \ / \ / \ / \             //
//     ( S | P | E | C | I | A | L )            //
//      \_/ \_/ \_/ \_/ \_/ \_/ \_/             //
//       _   _   _   _   _   _   _   _   _      //
//      / \ / \ / \ / \ / \ / \ / \ / \ / \     //
//     ( E | G | G | D | I | T | I | O | N )    //
//      \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/     //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract EGGS is ERC721Creator {
    constructor() ERC721Creator("SPECIAL EGGDITIONS", "EGGS") {}
}