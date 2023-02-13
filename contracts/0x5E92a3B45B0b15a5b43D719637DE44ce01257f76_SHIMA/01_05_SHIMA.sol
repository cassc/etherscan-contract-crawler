// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 1/1 PENCIL DRAWINGS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//       _   _   _   _   _     _   _   _   _   _   _   _   _   _      //
//      / \ / \ / \ / \ / \   / \ / \ / \ / \ / \ / \ / \ / \ / \     //
//     ( S | H | I | M | A ) ( V | O | S | U | G | H | I | A | N )    //
//      \_/ \_/ \_/ \_/ \_/   \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/     //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract SHIMA is ERC721Creator {
    constructor() ERC721Creator("1/1 PENCIL DRAWINGS", "SHIMA") {}
}