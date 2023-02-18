// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: blurchecks
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    Blur checks    //
//                   //
//                   //
///////////////////////


contract blur is ERC721Creator {
    constructor() ERC721Creator("blurchecks", "blur") {}
}