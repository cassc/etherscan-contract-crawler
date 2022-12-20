// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DOT DOT8
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    _____  _____  _____      //
//    |  _  \|  _  ||_   _|    //
//    | | | || | | |  | |      //
//    | | | || | | |  | |      //
//    | |/ / \ \_/ /  | |      //
//    |___/   \___/   \_/      //
//                             //
//                             //
/////////////////////////////////


contract DOT is ERC721Creator {
    constructor() ERC721Creator("DOT DOT8", "DOT") {}
}