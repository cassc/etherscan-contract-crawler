// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MISA
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    ♪(๑ᴖ◡ᴖ๑)♪    //
//                 //
//                 //
/////////////////////


contract MISA is ERC721Creator {
    constructor() ERC721Creator("MISA", "MISA") {}
}