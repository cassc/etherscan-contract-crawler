// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: xu100
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    just have fun    //
//                     //
//                     //
/////////////////////////


contract graphics is ERC721Creator {
    constructor() ERC721Creator("xu100", "graphics") {}
}