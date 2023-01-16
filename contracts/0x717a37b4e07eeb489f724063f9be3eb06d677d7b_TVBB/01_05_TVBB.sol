// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Void
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//      _   _   _     _   _   _   _      //
//     / \ / \ / \   / \ / \ / \ / \     //
//    ( T | h | e ) ( V | o | i | d )    //
//     \_/ \_/ \_/   \_/ \_/ \_/ \_/     //
//                                       //
//                                       //
//                                       //
///////////////////////////////////////////


contract TVBB is ERC721Creator {
    constructor() ERC721Creator("The Void", "TVBB") {}
}