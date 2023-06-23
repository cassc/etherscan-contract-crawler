// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Moon Tinkers
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    MOON TINKERS    //
//                    //
//                    //
////////////////////////


contract MTKR is ERC721Creator {
    constructor() ERC721Creator("Moon Tinkers", "MTKR") {}
}