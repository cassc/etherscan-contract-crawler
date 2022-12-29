// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: À la Mode
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    À la Mode    //
//                 //
//                 //
//                 //
/////////////////////


contract ALAMODE is ERC721Creator {
    constructor() ERC721Creator(unicode"À la Mode", "ALAMODE") {}
}