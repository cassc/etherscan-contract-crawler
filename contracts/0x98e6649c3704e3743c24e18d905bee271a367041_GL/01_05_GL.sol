// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Glimmer
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//      _   _   _   _   _   _   _      //
//     / \ / \ / \ / \ / \ / \ / \     //
//    ( G | l | i | m | m | e | r )    //
//     \_/ \_/ \_/ \_/ \_/ \_/ \_/     //
//                                     //
//                                     //
/////////////////////////////////////////


contract GL is ERC1155Creator {
    constructor() ERC1155Creator("Glimmer", "GL") {}
}