// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Yume
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    ˙˚ʚ(´◡`)ɞ˚˙    //
//                   //
//                   //
///////////////////////


contract Yume is ERC721Creator {
    constructor() ERC721Creator("Yume", "Yume") {}
}